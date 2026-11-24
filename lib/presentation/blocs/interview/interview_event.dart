import 'package:equatable/equatable.dart';

abstract class InterviewEvent extends Equatable {
  const InterviewEvent();

  @override
  List<Object?> get props => [];
}

class SelectTopicEvent extends InterviewEvent {
  final String topic;
  const SelectTopicEvent(this.topic);

  @override
  List<Object?> get props => [topic];
}

class SelectLevelEvent extends InterviewEvent {
  final String level;
  const SelectLevelEvent(this.level);

  @override
  List<Object?> get props => [level];
}

class RequestQuestionEvent extends InterviewEvent {}

class UpdateAnswerEvent extends InterviewEvent {
  final String answer;
  const UpdateAnswerEvent(this.answer);

  @override
  List<Object?> get props => [answer];
}

class SubmitAnswerEvent extends InterviewEvent {}

class ResetInterviewEvent extends InterviewEvent {}

class ViewHistoryEvent extends InterviewEvent {}

class BackToSetupEvent extends InterviewEvent {}
