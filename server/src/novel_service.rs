use tonic::{Request,Response,Status}; // Подключаю защищённые запросы
use surrealdb::{Surreal,engine::remote::ws::Client,types::{Bytes,SurrealValue,ToSql}}; // Подключаю записи и бинарные звуки
use serde_json::Value; // Подключаю настройки новеллы
use sha2::{Digest,Sha256}; // Подключаю отпечатки файлов
use crate::romance_club::{*,novel_api_server::NovelApi}; // Подключаю контракт каталога

pub const LEGACY: &str = "novel:ladybug";
pub fn scope(value:&str) -> Result<String,Status> {
    if value.is_empty() {return Ok(LEGACY.into());}
    let id=value.strip_prefix("novel:").filter(|s| !s.is_empty() && s.len()<=64 && s.bytes().all(|c|c.is_ascii_alphanumeric() || c==b'_'))
        .ok_or_else(||Status::invalid_argument("Неверная новелла"))?;
    Ok(format!("novel:{id}"))
}
fn internal(error:impl std::fmt::Display)->Status {Status::internal(error.to_string())}

pub fn legacy_config()->Value {serde_json::from_str(include_str!("../story/legacy_novel_config.json")).expect("Проверенный шаблон новеллы")}

pub fn validate_config(value:&str)->Result<Value,Status> {
    if value.len()>96*1024 {return Err(Status::invalid_argument("Слишком много настроек"));}
    let config:Value=serde_json::from_str(value).map_err(|_|Status::invalid_argument("Неверные настройки новеллы"))?;
    for (name,limit) in [("relationships",32),("endings",32),("hidden",64)] {
        let rows=config[name].as_array().ok_or_else(||Status::invalid_argument("Не заполнен список настроек"))?;
        if rows.len()>limit {return Err(Status::invalid_argument("Слишком много карточек"));}
        let mut keys=std::collections::HashSet::new();
        for row in rows {
            let key=row[if name=="relationships" {"counter"} else {"key"}].as_str().unwrap_or_default();
            let title=row["title"].as_str().unwrap_or_default();
            if key.is_empty() || key.len()>128 || title.trim().is_empty() || title.chars().count()>100 || !keys.insert(key) {
                return Err(Status::invalid_argument("У карточек должны быть разные ключи и непустые названия"));
            }
            if row["hint"].as_str().unwrap_or_default().chars().count()>300 {return Err(Status::invalid_argument("Подсказка слишком длинная"));}
            if let Some(id)=row["image_id"].as_str().filter(|s|!s.is_empty()) {crate::asset_delete::asset_id(id)?;}
        }
    }
    if !config["final_episode_id"].as_i64().is_some_and(|n|(0..=i64::from(i32::MAX)).contains(&n)) {
        return Err(Status::invalid_argument("Неверный финальный эпизод"));
    }
    Ok(config)
}

fn novel(row:Value)->Novel {
    let text=|key:&str|row[key].as_str().unwrap_or_default().to_owned();
    let id=text("id");
    let config=if id==LEGACY && row["config"].as_object().is_none_or(|c|c.is_empty()) {legacy_config()} else {row["config"].clone()};
    Novel {id,title:text("title"),cover_id:text("cover_id"),background_id:text("background_id"),music_id:text("music_id"),click_id:text("click_id"),config_json:config.to_string(),revision:row["revision"].as_i64().unwrap_or(1) as i32}
}

pub struct NovelApiService {pub db:Surreal<Client>}
impl NovelApiService {pub fn new(db:Surreal<Client>)->Self {Self {db}}}

#[derive(SurrealValue)]
struct AudioRow {id:surrealdb::types::RecordId,data:Bytes,hash:String}

#[tonic::async_trait]
impl NovelApi for NovelApiService {
    async fn list_novels(&self,_:Request<ListNovelsRequest>)->Result<Response<ListNovelsResponse>,Status> {
        let mut rows=self.db.query("SELECT * FROM novel ORDER BY id").await.map_err(internal)?.check().map_err(internal)?;
        let rows:Vec<Value>=rows.take(0).map_err(internal)?;
        Ok(Response::new(ListNovelsResponse {novels:rows.into_iter().map(novel).collect()}))
    }

    async fn save_novel(&self,request:Request<Novel>)->Result<Response<Novel>,Status> {
        crate::request_auth::check_current_admin(&request,&self.db).await?;
        let mut item=request.into_inner();
        let create=item.id.is_empty();
        if create {item.id=format!("novel:n_{}",uuid::Uuid::new_v4().simple());} else {item.id=scope(&item.id)?;}
        if item.title.trim().is_empty() || item.title.chars().count()>100 || item.revision<0 {return Err(Status::invalid_argument("Укажи название новеллы"));}
        for id in [&item.cover_id,&item.background_id].into_iter().filter(|s|!s.is_empty()) {crate::asset_delete::asset_id(id)?;}
        let config=validate_config(&item.config_json)?;
        let revision=item.revision.checked_add(1).ok_or_else(||Status::invalid_argument("Слишком большая версия"))?;
        let mut result=self.db.query("BEGIN TRANSACTION; LET $key=type::record($id); LET $old=SELECT * FROM ONLY $key; IF ($create AND $old!=NONE) OR (!$create AND ($old=NONE OR $old.revision!=$expected)) {THROW 'NOVEL_CONFLICT';}; FOR $image IN [$cover,$background] { IF $image!='' AND !record::exists(type::record($image)) {THROW 'NOVEL_IMAGE_INVALID';}; }; IF $config.final_episode_id>0 AND array::len(SELECT VALUE id FROM episode WHERE id=type::record('episode',$config.final_episode_id) AND novel_id=$key)=0 {THROW 'NOVEL_FINAL_INVALID';}; FOR $audio IN [$music,$click] { IF $audio!='' AND array::len(SELECT VALUE id FROM novel_audio WHERE id=type::record($audio) AND novel_id=$key)=0 {THROW 'NOVEL_AUDIO_INVALID';}; }; UPSERT $key CONTENT {title:$title,cover_id:$cover,background_id:$background,music_id:$music,click_id:$click,config:$config,revision:$revision}; COMMIT TRANSACTION;")
            .bind(("id",item.id.clone())).bind(("create",create)).bind(("expected",item.revision)).bind(("revision",revision))
            .bind(("title",item.title.trim().to_owned())).bind(("cover",item.cover_id.clone())).bind(("background",item.background_id.clone()))
            .bind(("music",item.music_id.clone())).bind(("click",item.click_id.clone())).bind(("config",config)).await.map_err(internal)?;
        let errors=result.take_errors();
        if !errors.is_empty() {return Err(Status::aborted("Новелла не сохранена: обнови редактор и проверь выбранные звуки"));}
        item.revision=revision;
        Ok(Response::new(item))
    }

    async fn create_novel_episode(&self,request:Request<CreateNovelEpisodeRequest>)->Result<Response<Episode>,Status> {
        crate::request_auth::check_current_admin(&request,&self.db).await?;
        let request=request.into_inner();let novel_id=scope(&request.novel_id)?;
        let title=if request.title.trim().is_empty(){"Новый эпизод".into()}else{request.title.trim().to_owned()};
        if title.chars().count()>100 {return Err(Status::invalid_argument("Название слишком длинное"));}
        for _ in 0..8 {
            let mut result=self.db.query("BEGIN TRANSACTION; IF !record::exists(type::record($novel)) {THROW 'NOVEL_NOT_FOUND';}; LET $highest=math::max((SELECT VALUE <int>record::id(id) FROM episode)) ?? 0; LET $counter=SELECT * FROM ONLY story_sequence:episodes; LET $next=math::max([$highest,$counter.value ?? 0])+1; IF $next>2147483647 {THROW 'EPISODE_ID_OVERFLOW';}; UPSERT story_sequence:episodes CONTENT {value:$next}; CREATE type::record('episode',$next) CONTENT {title:$title,version:1,novel_id:type::record($novel),created_at:time::now(),updated_at:time::now()}; RETURN {id:$next,title:$title}; COMMIT TRANSACTION;")
                .bind(("novel",novel_id.clone())).bind(("title",title.clone())).await.map_err(internal)?;
            let errors=result.take_errors();
            if !errors.is_empty() {
                if errors.values().any(|e|matches!(e.query_details(),Some(surrealdb::types::QueryError::TransactionConflict))) {continue;}
                return Err(Status::failed_precondition("Не удалось создать эпизод этой новеллы"));
            }
            for i in 0..result.num_statements() {
                if let Ok(Some(row))=result.take::<Option<Value>>(i) {
                    if let Some(id)=row["id"].as_i64() {return Ok(Response::new(Episode {id:id as i32,title,version:1,scenes:vec![],novel_id}));}
                }
            }
            return Err(Status::internal("Не получен номер нового эпизода"));
        }
        Err(Status::aborted("Повтори создание эпизода"))
    }

    async fn upload_audio(&self,request:Request<UploadNovelAudioRequest>)->Result<Response<NovelAudio>,Status> {
        crate::request_auth::check_current_admin(&request,&self.db).await?;
        let request=request.into_inner();let novel_id=scope(&request.novel_id)?;
        if !matches!(request.kind.as_str(),"music"|"click") {return Err(Status::invalid_argument("Неверный вид звука"));}
        // Ограничиваю параллельную обработку звука и не занимаю async-поток разбором файла.
        static AUDIO_WORKERS:tokio::sync::Semaphore=tokio::sync::Semaphore::const_new(2);
        let permit=AUDIO_WORKERS.try_acquire().map_err(|_|Status::resource_exhausted("Загрузка звуков занята, повтори позже"))?;
        let bytes=request.data;
        let max_seconds=if request.kind=="click" {15.0}else{600.0};
        let (bytes,hash)=tokio::task::spawn_blocking(move || {
            let _permit=permit;
            crate::novel_audio::validate(&bytes,max_seconds)?;
            let hash=format!("{:x}",Sha256::digest(&bytes));
            Ok::<_,Status>((bytes,hash))
        }).await.map_err(internal)??;
        let id=format!("novel_audio:a_{}",uuid::Uuid::new_v4().simple());
        self.db.query("IF !record::exists(type::record($novel)) {THROW 'NOVEL_NOT_FOUND';}; CREATE type::record($id) CONTENT {novel_id:type::record($novel),kind:$kind,data:$data,hash:$hash};")
            .bind(("id",id.clone())).bind(("novel",novel_id)).bind(("kind",request.kind)).bind(("data",Bytes::from(bytes))).bind(("hash",hash.clone()))
            .await.map_err(internal)?.check().map_err(internal)?;
        Ok(Response::new(NovelAudio {id,hash,data:vec![]}))
    }

    async fn get_audio(&self,request:Request<NovelAudioRequest>)->Result<Response<NovelAudio>,Status> {
        let request=request.into_inner();let novel_id=scope(&request.novel_id)?;
        if !request.id.starts_with("novel_audio:") || request.id.len()>120 {return Err(Status::invalid_argument("Неверный звук"));}
        let mut result=self.db.query("SELECT id,data,hash FROM novel_audio WHERE id=type::record($id) AND novel_id=type::record($novel)")
            .bind(("id",request.id)).bind(("novel",novel_id)).await.map_err(internal)?.check().map_err(internal)?;
        let rows:Vec<AudioRow>=result.take(0).map_err(internal)?;
        let row=rows.into_iter().next().ok_or_else(||Status::not_found("Звук не найден"))?;
        Ok(Response::new(NovelAudio {id:row.id.to_sql(),data:row.data.to_vec(),hash:row.hash}))
    }
}