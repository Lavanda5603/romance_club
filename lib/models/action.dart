class Action {
  final String type;
  final int? sceneId;
  final String? flagName;
  final bool? flagValue;
  final String? counterName;
  final int? counterValue;
  final String? soundPath;
  final String? imagePath;

  const Action({
    required this.type,
    this.sceneId,
    this.flagName,
    this.flagValue,
    this.counterName,
    this.counterValue,
    this.soundPath,
    this.imagePath,  
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    if (sceneId != null) 'sceneId': sceneId,
    if (flagName != null) 'flagName': flagName,
    if (flagValue != null) 'flagValue': flagValue,
    if (counterName != null) 'counterName': counterName,
    if (counterValue != null) 'counterValue': counterValue,
    if (soundPath != null) 'soundPath': soundPath,
    if (imagePath != null) 'imagePath': imagePath,
  };

  factory Action.fromJson(Map<String, dynamic> json) => Action(
    type: json['type'],
    sceneId: json['sceneId'],
    flagName: json['flagName'],
    flagValue: json['flagValue'],
    counterName: json['counterName'],
    counterValue: json['counterValue'],
    soundPath: json['soundPath'],
    imagePath: json['imagePath'],
  );
}