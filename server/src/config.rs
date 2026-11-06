use std::{io, net::SocketAddr};

pub struct Config {
    pub grpc_bind: SocketAddr,
    pub surreal_endpoint: String,
    pub surreal_user: String,
    pub surreal_pass: String,
    pub namespace: String,
    pub database: String,
}

impl Config {
    pub fn from_env() -> Result<Self, io::Error> {
        Self::from_lookup(|key| std::env::var(key).ok())
    }

    fn from_lookup(get: impl Fn(&str) -> Option<String>) -> Result<Self, io::Error> {
        let required = |key| {
            get(key).filter(|value| !value.trim().is_empty()).ok_or_else(|| {
                io::Error::new(io::ErrorKind::InvalidInput, format!("Не задан {key}"))
            })
        };
        Ok(Self {
            grpc_bind: get("GRPC_BIND")
                .unwrap_or_else(|| "127.0.0.1:50051".into())
                .parse()
                .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "Неверный GRPC_BIND"))?,
            surreal_endpoint: get("SURREAL_ENDPOINT")
                .unwrap_or_else(|| "127.0.0.1:8000/rpc".into()),
            surreal_user: required("SURREAL_USER")?,
            surreal_pass: required("SURREAL_PASS")?,
            namespace: get("SURREAL_NAMESPACE").unwrap_or_else(|| "romance_club".into()),
            database: get("SURREAL_DATABASE").unwrap_or_else(|| "main".into()),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn requires_credentials_and_defaults_to_loopback() {
        assert!(Config::from_lookup(|_| None).is_err());
        let config = Config::from_lookup(|key| match key {
            "SURREAL_USER" => Some("test_user".into()),
            "SURREAL_PASS" => Some("test_password".into()),
            _ => None,
        }).unwrap();
        assert!(config.grpc_bind.ip().is_loopback());
        assert_eq!(config.surreal_endpoint, "127.0.0.1:8000/rpc");
    }

    #[test]
    fn accepts_lan_binding_and_remote_database() {
        let get = |key: &str| Some(match key {
            "GRPC_BIND" => "0.0.0.0:50052",
            "SURREAL_ENDPOINT" => "db.internal:8000/rpc",
            "SURREAL_USER" => "test_user",
            "SURREAL_PASS" => "test_password",
            "SURREAL_NAMESPACE" => "custom",
            "SURREAL_DATABASE" => "development",
            _ => return None,
        }.into());
        let config = Config::from_lookup(get).unwrap();
        assert_eq!(config.grpc_bind.port(), 50052);
        assert!(config.grpc_bind.ip().is_unspecified());
        assert_eq!(config.surreal_endpoint, "db.internal:8000/rpc");
        assert_eq!(config.namespace, "custom");
        assert_eq!(config.database, "development");
        assert!(Config::from_lookup(|key| if key == "GRPC_BIND" {
            Some("invalid".into())
        } else { get(key) }).is_err());
    }
}
