import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:dose_repository/dose_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:medical_reminder/create_treatment/form_inputs/form_inputs.dart';
import 'package:treatment_repository/treatment_repository.dart';

part 'create_treatment_state.dart';

part 'create_treatment_event.dart';

class CreateTreatmentBloc
    extends Bloc<CreateTreatmentEvent, CreateTreatmentState> {
  CreateTreatmentBloc({
    required this.userId,
    required this.treatmentRepository,
    required this.doseRepository,
  }) : super(const CreateTreatmentState()) {
    on<InitializeCreateTreatmentEvent>(_onInitialize);
    on<MedicationChangedCreteTreatmentEvent>(_onMedicationChanged);
    on<StartDateChangedCreateTreatmentEvent>(_onStartDateChanged);
    on<EndDateChangedCreateTreatmentEvent>(_onEndDateChanged);
    on<FrequencyChangedCreateTreatmentEvent>(_onFrequencyChanged);
    on<SubmitCreateTreatmentEvent>(_onSubmit);
    on<ClearCreateTreatmentEvent>(_onClear);
  }

  final TreatmentRepository treatmentRepository;
  final DoseRepository doseRepository;
  final String userId;

  FutureOr<void> _onInitialize(
    InitializeCreateTreatmentEvent event,
    Emitter<CreateTreatmentState> emit,
  ) {
    emit(
      state.copyWith(
        userId: event.userId,
        medication: event.medication,
      ),
    );
  }

  FutureOr<void> _onStartDateChanged(
    StartDateChangedCreateTreatmentEvent event,
    Emitter<CreateTreatmentState> emit,
  ) {
    emit(
      state.copyWith(
        startDate: event.date,
        status: Formz.validate([
          state.medication,
          event.date,
          state.endDate,
          state.frequency,
        ]),
      ),
    );
  }

  FutureOr<void> _onEndDateChanged(
    EndDateChangedCreateTreatmentEvent event,
    Emitter<CreateTreatmentState> emit,
  ) {
    emit(
      state.copyWith(
        endDate: event.date,
        status: Formz.validate([
          state.medication,
          state.startDate,
          event.date,
          state.frequency,
        ]),
      ),
    );
  }

  FutureOr<void> _onFrequencyChanged(
    FrequencyChangedCreateTreatmentEvent event,
    Emitter<CreateTreatmentState> emit,
  ) {
    final s = state.copyWith(
      frequency: event.frequency,
      status: Formz.validate([
        state.medication,
        state.startDate,
        state.endDate,
        event.frequency,
      ]),
    );
    emit(s);
  }

  FutureOr<void> _onMedicationChanged(
    MedicationChangedCreteTreatmentEvent event,
    Emitter<CreateTreatmentState> emit,
  ) {
    emit(
      state.copyWith(
        medication: event.medication,
        status: Formz.validate([
          event.medication,
          state.startDate,
          state.endDate,
          state.frequency,
        ]),
      ),
    );
  }

  FutureOr<void> _onSubmit(
    SubmitCreateTreatmentEvent event,
    Emitter<CreateTreatmentState> emit,
  ) async {
    try {
      log('submit');
      final treatment = Treatment(
        userId: userId,
        medicationId: state.medication.value!.nregistro!,
        startDate: state.startDate.value!,
        endDate: state.endDate.value != null ? state.endDate.value! : null,
        frequencyHours: state.frequency.value ?? 0,
      );
      await treatmentRepository.addTreatment(treatment);
      var doseDateTime = treatment.startDate;
      while (doseDateTime.isBefore(treatment.endDate!)) {
        final dose = Dose(
          sheduledDateTime: doseDateTime,
          treatmentId: treatment.id,
        );
        await doseRepository.addDose(dose);
        doseDateTime = doseDateTime.add(
          Duration(hours: treatment.frequencyHours),
        );
      }
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } on Exception catch (e) {
      log('Error: $e');
      emit(state.copyWith(status: FormzStatus.submissionFailure));
    }
  }

  FutureOr<void> _onClear(
    ClearCreateTreatmentEvent event,
    Emitter<CreateTreatmentState> emit,
  ) {
    emit(const CreateTreatmentState());
  }
}
