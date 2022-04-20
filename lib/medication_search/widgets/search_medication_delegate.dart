import 'dart:developer';
import 'package:cima_repository/cima_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_reminder/medication_search/bloc/medication_search_bloc.dart';
import 'package:medical_reminder/medication_search/widgets/medication_search_item_result_list.dart';

class SearchMedicationDelegate extends SearchDelegate<Medicamento?> {
  SearchMedicationDelegate(this.medicationSearchBloc);

  final MedicationSearchBloc medicationSearchBloc;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
      IconButton(
        icon: const Icon(Icons.camera_alt),
        onPressed: () {
          // TODO(asignes): open camera to scan code bar
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    log('buildResults');
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length > 3) {
      medicationSearchBloc.add(MedicationsFetched(name: query));
      return BlocBuilder<MedicationSearchBloc, MedicationSearchState>(
        bloc: medicationSearchBloc,
        builder: (context, state) {
          switch (state.status) {
            case MedicationSearchStatus.initial:
            case MedicationSearchStatus.loading:
              return const Center(
                child: CircularProgressIndicator(),
              );
            case MedicationSearchStatus.loaded:
            case MedicationSearchStatus.error:
              return ListView.builder(
                itemCount: state.medications.length,
                itemBuilder: (context, index) {
                  final medication = state.medications[index];
                  return MedicationSearchItemResultList(medication: medication);
                },
              );
          }
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context);
}
