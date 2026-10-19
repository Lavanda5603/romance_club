use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier, password_hash::{rand_core::OsRng, SaltString}}; // Подключаю Argon2 и соль пароля
use std::{sync::{Arc, LazyLock}, time::Duration}; // Подключаю общее состояние и срок ожидания
use tokio::sync::Semaphore; // Подключаю ограничение очереди и вычислений
use tonic::Status; // Подключаю ошибки gRPC

// Один пул для регистрации и входа во всех экземплярах сервиса
static PASSWORDS: LazyLock<PasswordPool> = LazyLock::new(|| PasswordPool::new(2, 8, Duration::from_secs(10)));

struct PasswordPool {
    workers: Arc<Semaphore>,
    admitted: Arc<Semaphore>,
    queue_wait: Duration,
}

impl PasswordPool {
    fn new(workers: usize, waiting: usize, queue_wait: Duration) -> Self {
        Self { workers: Arc::new(Semaphore::new(workers)),
            admitted: Arc::new(Semaphore::new(workers + waiting)), queue_wait }
    }

    async fn run<T, F>(&self, work: F) -> Result<T, Status>
    where T: Send + 'static, F: FnOnce() -> Result<T, Status> + Send + 'static {
        // Лишние запросы отклоняю сразу, не создавая неограниченную очередь
        let admitted = self.admitted.clone().try_acquire_owned()
            .map_err(|_| Status::resource_exhausted("Слишком много запросов входа и регистрации. Повторите позже"))?;
        let worker = tokio::time::timeout(self.queue_wait, self.workers.clone().acquire_owned()).await
            .map_err(|_| Status::resource_exhausted("Сервер занят. Повторите вход или регистрацию"))?
            .map_err(|_| Status::unavailable("Обработка паролей недоступна"))?;
        tokio::task::spawn_blocking(move || {
            // При отмене RPC слот остаётся занят до настоящего завершения вычисления
            let _admitted = admitted;
            let _worker = worker;
            work()
        }).await.map_err(|_| Status::internal("Ошибка обработки пароля"))?
    }
}

pub async fn hash(password: String) -> Result<String, Status> {
    PASSWORDS.run(move || {
        let salt = SaltString::generate(&mut OsRng);
        Argon2::default().hash_password(password.as_bytes(), &salt)
            .map(|hash| hash.to_string())
            .map_err(|_| Status::internal("Не удалось вычислить хеш пароля"))
    }).await
}

pub async fn verify(password: String, hash: String) -> Result<bool, Status> {
    PASSWORDS.run(move || {
        let parsed = match PasswordHash::new(&hash) {
            Ok(parsed) => parsed,
            Err(_) => return Ok(false),
        };
        Ok(Argon2::default().verify_password(password.as_bytes(), &parsed).is_ok())
    }).await
}

#[cfg(test)]
#[path = "password_work_tests.rs"]
mod tests; // Проверки очереди, отмены и вычислений
