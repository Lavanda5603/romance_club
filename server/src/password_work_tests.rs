use super::*; // Подключаю пул паролей
use std::sync::{mpsc, atomic::{AtomicBool, Ordering}}; // Подключаю управление тестовой CPU-задачей
use tonic::Code; // Подключаю коды ошибок gRPC

// Удерживаю blocking-задачу, пока тест проверяет работу async-потока
async fn hold(pool: Arc<PasswordPool>) -> (tokio::task::JoinHandle<Result<(), Status>>, mpsc::Sender<()>) {
    let (release, wait) = mpsc::channel();
    let (started, ready) = tokio::sync::oneshot::channel();
    let task = tokio::spawn(async move { pool.run(move || {
        started.send(()).unwrap();
        wait.recv_timeout(Duration::from_secs(5)).map_err(|_| Status::internal("Тест не освободил задачу"))?;
        Ok(())
    }).await });
    tokio::time::timeout(Duration::from_secs(2), ready).await.unwrap().unwrap();
    (task, release)
}

#[tokio::test(flavor = "current_thread")]
async fn two_cpu_jobs_do_not_block_async_runtime() {
    let pool = Arc::new(PasswordPool::new(2, 0, Duration::from_secs(1)));
    let (a, release_a) = hold(pool.clone()).await;
    let (b, release_b) = hold(pool.clone()).await;
    // Таймер работает даже на одном async-потоке, пока обе CPU-задачи заняты
    tokio::time::timeout(Duration::from_millis(500), tokio::time::sleep(Duration::from_millis(10))).await.unwrap();
    assert!(!a.is_finished() && !b.is_finished());
    assert_eq!(pool.workers.available_permits(), 0);
    assert_eq!(pool.run(|| Ok(())).await.unwrap_err().code(), Code::ResourceExhausted);
    release_a.send(()).unwrap();
    release_b.send(()).unwrap();
    a.await.unwrap().unwrap();
    b.await.unwrap().unwrap();
    assert_eq!(pool.workers.available_permits(), 2);
}

#[tokio::test]
async fn waiting_queue_is_bounded_and_cancelled_waiter_releases_capacity() {
    let pool = Arc::new(PasswordPool::new(1, 1, Duration::from_secs(2)));
    let (active, release) = hold(pool.clone()).await;
    let called = Arc::new(AtomicBool::new(false));
    let flag = called.clone();
    let waiting_pool = pool.clone();
    let waiting = tokio::spawn(async move { waiting_pool.run(move || {flag.store(true, Ordering::SeqCst); Ok(())}).await });
    tokio::time::timeout(Duration::from_secs(1), async {
        while pool.admitted.available_permits() != 0 { tokio::task::yield_now().await; }
    }).await.unwrap();
    assert_eq!(pool.run(|| Ok(())).await.unwrap_err().code(), Code::ResourceExhausted);
    assert!(!called.load(Ordering::SeqCst));
    waiting.abort();
    assert!(waiting.await.unwrap_err().is_cancelled());
    assert_eq!(pool.admitted.available_permits(), 1);
    release.send(()).unwrap();
    active.await.unwrap().unwrap();
    assert_eq!(pool.admitted.available_permits(), 2);
    assert!(!called.load(Ordering::SeqCst));
}

#[tokio::test]
async fn expired_queue_does_not_start_cpu_work() {
    let pool = Arc::new(PasswordPool::new(1, 1, Duration::from_millis(20)));
    let (active, release) = hold(pool.clone()).await;
    let called = Arc::new(AtomicBool::new(false));
    let flag = called.clone();
    assert_eq!(pool.run(move || {flag.store(true, Ordering::SeqCst); Ok(())}).await.unwrap_err().code(), Code::ResourceExhausted);
    assert!(!called.load(Ordering::SeqCst));
    assert_eq!(pool.admitted.available_permits(), 1);
    release.send(()).unwrap();
    active.await.unwrap().unwrap();
}

#[tokio::test]
async fn cancelling_rpc_does_not_release_running_cpu_slot() {
    let pool = Arc::new(PasswordPool::new(1, 0, Duration::from_secs(1)));
    let (active, release) = hold(pool.clone()).await;
    active.abort();
    assert!(active.await.unwrap_err().is_cancelled());
    assert_eq!(pool.workers.available_permits(), 0);
    assert_eq!(pool.admitted.available_permits(), 0);
    assert_eq!(pool.run(|| Ok(())).await.unwrap_err().code(), Code::ResourceExhausted);
    release.send(()).unwrap();
    // Ёмкость возвращается только после фактического завершения blocking-задачи
    let permit = tokio::time::timeout(Duration::from_secs(2), pool.admitted.acquire()).await.unwrap().unwrap();
    drop(permit);
    assert_eq!(pool.run(|| Ok(7)).await.unwrap(), 7);
}

#[tokio::test]
async fn panic_returns_error_and_releases_worker() {
    let pool = PasswordPool::new(1, 0, Duration::from_secs(1));
    assert_eq!(pool.run::<(), _>(|| panic!("test worker panic")).await.unwrap_err().code(), Code::Internal);
    assert_eq!(pool.run(|| Ok(7)).await.unwrap(), 7);
}

#[tokio::test]
async fn argon2_hash_and_verification_keep_existing_password_behaviour() {
    let first = hash("Password1!".into()).await.unwrap();
    assert!(first.starts_with("$argon2id$"));
    assert!(verify("Password1!".into(), first.clone()).await.unwrap());
    assert!(!verify("Wrong1!".into(), first.clone()).await.unwrap());
    assert!(!verify("Password1!".into(), "broken_hash".into()).await.unwrap());
    let second = hash("Password1!".into()).await.unwrap();
    assert_ne!(first, second);
}
