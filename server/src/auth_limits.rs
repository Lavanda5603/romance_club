use std::{collections::HashMap, net::{IpAddr, Ipv4Addr}, sync::{Arc, LazyLock, Mutex}, time::{Duration, Instant}}; // Подключаю адрес клиента, счётчики и монотонное время
use tonic::{Request, Status}; // Подключаю запрос и ошибку ограничения

pub const MAX_AUTH_MESSAGE_BYTES: usize = 4096;
const MAX_ENTRIES: usize = 20_000;
static ATTEMPTS: LazyLock<Arc<AuthLimits>> = LazyLock::new(|| Arc::new(AuthLimits::new()));
pub fn shared() -> Arc<AuthLimits> { ATTEMPTS.clone() }

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum Operation { Login, Register }

#[derive(Eq, Hash, PartialEq)]
enum Key {
    Source(IpAddr),
    RegisterSource(IpAddr),
    Account(Operation, String),
    Pair(Operation, IpAddr, String),
}
struct Bucket { used: u32, until: Instant }
struct State { entries: HashMap<Key, Bucket>, next_cleanup: Instant }
type Clock = Arc<dyn Fn() -> Instant + Send + Sync>;
pub struct AuthLimits { state: Mutex<State>, capacity: usize, clock: Clock }

// Беру адрес из транспорта, а не из подставленного X-Forwarded-For
pub fn peer_ip<T>(request: &Request<T>) -> IpAddr {
    match request.remote_addr().map(|addr| addr.ip()).unwrap_or(IpAddr::V4(Ipv4Addr::UNSPECIFIED)) {
        IpAddr::V6(ip) => ip.to_ipv4_mapped().map(IpAddr::V4).unwrap_or(IpAddr::V6(ip)),
        ip => ip,
    }
}

// Размеры проверяю до логирования, обращения к базе и вычисления пароля
pub fn check_fields(login: &str, email: Option<&str>, password: &str) -> Result<(), Status> {
    if login.len() > 64 { return Err(Status::invalid_argument("Слишком длинный логин")); }
    if email.is_some_and(|email| email.len() > 254) { return Err(Status::invalid_argument("Слишком длинный email")); }
    if password.len() > 1024 { return Err(Status::invalid_argument("Слишком длинный пароль")); }
    Ok(())
}

fn blocked(wait: Duration) -> Status {
    let seconds = wait.as_secs().saturating_add(u64::from(wait.subsec_nanos() > 0)).max(1);
    let mut status = Status::resource_exhausted(format!("Слишком много попыток. Повторите через {seconds} сек."));
    if let Ok(value) = seconds.to_string().parse() { status.metadata_mut().insert("retry-after", value); }
    status
}

impl AuthLimits {
    fn new() -> Self { Self::configured(MAX_ENTRIES, Arc::new(Instant::now)) }
    fn configured(capacity: usize, clock: Clock) -> Self {
        Self { state: Mutex::new(State { entries:HashMap::new(), next_cleanup:clock() }), capacity, clock }
    }
    #[cfg(test)]
    pub fn testing(capacity: usize, clock: Clock) -> Self { Self::configured(capacity, clock) }

    pub fn check_source(&self, ip: IpAddr, operation: Operation) -> Result<(), Status> {
        let mut rules = vec![(Key::Source(ip), 30, Duration::from_secs(60))];
        if operation == Operation::Register { rules.push((Key::RegisterSource(ip), 5, Duration::from_secs(60))); }
        self.check(rules)
    }

    pub fn check_account(&self, ip: IpAddr, login: &str, operation: Operation) -> Result<(), Status> {
        self.check(vec![
            (Key::Account(operation, login.to_owned()), 20, Duration::from_secs(60)),
            (Key::Pair(operation, ip, login.to_owned()), 5, Duration::from_secs(30)),
        ])
    }

    fn check(&self, rules: Vec<(Key, u32, Duration)>) -> Result<(), Status> {
        let now = (self.clock)();
        let mut state = self.state.lock().map_err(|_| Status::internal("Учёт попыток временно недоступен"))?;
        // Не сканирую весь список на каждом запросе и не храню адреса бесконечно
        if now >= state.next_cleanup {
            state.entries.retain(|_, bucket| bucket.until > now);
            state.next_cleanup = now + Duration::from_secs(1);
        }
        let wait = rules.iter().filter_map(|(key, limit, _)| state.entries.get(key)
            .filter(|bucket| bucket.until > now && bucket.used >= *limit)
            .map(|bucket| bucket.until.duration_since(now))).max();
        if let Some(wait) = wait { return Err(blocked(wait)); }
        let new_entries = rules.iter().filter(|(key, _, _)| !state.entries.contains_key(key)).count();
        if state.entries.len() + new_entries > self.capacity { return Err(blocked(Duration::from_secs(1))); }
        // Проверяю все квоты до изменения счётчиков; отказ не продлевает окно
        for (key, _, window) in rules {
            let bucket = state.entries.entry(key).or_insert(Bucket {used:0, until:now + window});
            if bucket.until <= now { *bucket = Bucket {used:0, until:now + window}; }
            bucket.used += 1;
        }
        Ok(())
    }
}

#[cfg(test)]
#[path = "auth_limits_tests.rs"]
mod tests; // Проверки квот и публичного gRPC