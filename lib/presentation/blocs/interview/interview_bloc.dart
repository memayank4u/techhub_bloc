import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/common/resource.dart';
import '../../../domain/entities/interview_session_entity.dart';
import '../../../domain/usecases/evaluate_answer_usecase.dart';
import '../../../domain/usecases/generate_question_usecase.dart';
import '../../../domain/usecases/get_interview_history_usecase.dart';
import '../../../domain/usecases/save_interview_session_usecase.dart';
import 'interview_event.dart';
import 'interview_state.dart';

class InterviewBloc extends Bloc<InterviewEvent, InterviewState> {
  final GenerateQuestionUseCase generateQuestionUseCase;
  final EvaluateAnswerUseCase evaluateAnswerUseCase;
  final GetInterviewHistoryUseCase getHistoryUseCase;
  final SaveInterviewSessionUseCase saveSessionUseCase;

  InterviewBloc({
    required this.generateQuestionUseCase,
    required this.evaluateAnswerUseCase,
    required this.getHistoryUseCase,
    required this.saveSessionUseCase,
  }) : super(const InterviewState()) {
    on<SelectTopicEvent>((e, emit) => emit(state.copyWith(selectedTopic: e.topic)));
    on<SelectLevelEvent>((e, emit) => emit(state.copyWith(selectedLevel: e.level)));
    on<UpdateAnswerEvent>((e, emit) => emit(state.copyWith(userAnswer: e.answer)));
    on<ResetInterviewEvent>((e, emit) => emit(state.copyWith(
          currentQuestion: '',
          userAnswer: '',
          streamingEvaluation: '',
          step: InterviewStep.setup,
        )));
    on<ViewHistoryEvent>((e, emit) {
      final history = getHistoryUseCase();
      emit(state.copyWith(step: InterviewStep.history, historySessions: history));
    });
    on<BackToSetupEvent>((e, emit) => emit(state.copyWith(step: InterviewStep.setup)));

    on<RequestQuestionEvent>(_onRequestQuestion);
    on<SubmitAnswerEvent>(_onSubmitAnswer);
  }

  Future<void> _onRequestQuestion(
    RequestQuestionEvent event,
    Emitter<InterviewState> emit,
  ) async {
    emit(state.copyWith(isGeneratingQuestion: true, errorMessage: null));

    await emit.forEach(
      generateQuestionUseCase(state.selectedTopic, state.selectedLevel),
      onData: (resource) {
        if (resource is ResourceSuccess) {
          return state.copyWith(
            isGeneratingQuestion: false,
            currentQuestion: resource.data ?? '',
            userAnswer: '',
            streamingEvaluation: '',
            step: InterviewStep.questionActive,
          );
        } else if (resource is ResourceError) {
          return state.copyWith(
            isGeneratingQuestion: false,
            errorMessage: resource.message,
          );
        }
        return state;
      },
    );
  }

  Future<void> _onSubmitAnswer(
    SubmitAnswerEvent event,
    Emitter<InterviewState> emit,
  ) async {
    if (state.userAnswer.trim().isEmpty) return;

    emit(state.copyWith(
      step: InterviewStep.evaluating,
      isEvaluatingAnswer: true,
      streamingEvaluation: '',
    ));

    String finalEvaluation = '';

    await emit.forEach(
      evaluateAnswerUseCase(state.currentQuestion, state.userAnswer),
      onData: (resource) {
        if (resource is ResourceSuccess) {
          finalEvaluation = resource.data ?? '';
          return state.copyWith(
            isEvaluatingAnswer: false,
            streamingEvaluation: finalEvaluation,
            step: InterviewStep.evaluationResult,
          );
        }
        return state;
      },
    );

    // Auto-save completed session to Hive
    if (finalEvaluation.isNotEmpty) {
      final score = _extractScore(finalEvaluation);
      final session = InterviewSessionEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: state.selectedTopic,
        level: state.selectedLevel,
        question: state.currentQuestion,
        userAnswer: state.userAnswer,
        score: score,
        evaluationFeedback: finalEvaluation,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      await saveSessionUseCase(session);
    }
  }

  int _extractScore(String text) {
    final match = RegExp(r'(\d+)/10').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '8') ?? 8;
    }
    return 8;
  }
}
