use tonic::Status; // Подключаю понятные ошибки загрузки MP3

// Проверяю цепочку кадров без распаковки звука в память сервера.
pub fn validate(data:&[u8],max_seconds:f64)->Result<(),Status> {
    let invalid=||Status::invalid_argument("Нужен корректный MP3, музыка до 10 минут, щелчок до 15 секунд");
    if data.is_empty() || data.len()>15*1024*1024 {return Err(Status::invalid_argument("MP3 должен быть не больше 15 MiB"));}
    let mut offset=0;
    if data.starts_with(b"ID3") {
        if data.len()<10 || data[6..10].iter().any(|b|b&128!=0) {return Err(invalid());}
        let size=data[6..10].iter().fold(0usize,|n,b|(n<<7)|usize::from(*b));
        offset=10+size+if data[5]&16!=0 {10}else{0};
    }
    let mut seconds=0.0;let mut frames=0;
    while offset+4<=data.len() {
        let remaining=&data[offset..];
        if (remaining[0]==0 && remaining.iter().all(|b|*b==0)) || (remaining.len()==128 && remaining.starts_with(b"TAG")) {break;}
        let header=u32::from_be_bytes(data[offset..offset+4].try_into().map_err(|_|invalid())?);
        let version=(header>>19)&3;let layer=(header>>17)&3;
        let bitrate=((header>>12)&15) as usize;let sample=((header>>10)&3) as usize;
        if header>>21!=0x7ff || version==1 || layer!=1 || bitrate==0 || bitrate==15 || sample==3 {return Err(invalid());}
        let rates1:[u32;15]=[0,32,40,48,56,64,80,96,112,128,160,192,224,256,320];
        let rates2:[u32;15]=[0,8,16,24,32,40,48,56,64,80,96,112,128,144,160];
        let hz=[44100,48000,32000][sample]/if version==3 {1}else if version==2 {2}else{4};
        let rate=if version==3 {rates1[bitrate]}else{rates2[bitrate]};
        let length=((if version==3 {144000}else{72000})*rate/hz+((header>>9)&1)) as usize;
        if length<4 || offset+length>data.len() {return Err(invalid());}
        seconds+=f64::from(if version==3 {1152}else{576})/f64::from(hz);
        if seconds>max_seconds {return Err(invalid());}
        frames+=1;offset+=length;
    }
    if frames<2 || (offset<data.len() && !data[offset..].iter().all(|b|*b==0) && !(data.len()-offset==128 && data[offset..].starts_with(b"TAG"))) {return Err(invalid());}
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn accepts_project_mp3_and_rejects_garbage() {
        assert!(validate(include_bytes!("../../assets/audio/background_music.mp3"),600.0).is_ok());
        assert!(validate(include_bytes!("../../assets/audio/button_click.mp3"),15.0).is_ok());
        assert!(validate(b"ID3not_audio",600.0).is_err());
        assert!(validate(include_bytes!("../../assets/audio/background_music.mp3"),15.0).is_err());
    }
}