import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rutracker_api/rutracker_api.dart';
import 'package:rutracker_app/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:rutracker_app/models/query_response.dart';
import 'package:rutracker_app/repository/search_repository.dart';

part 'search_event.dart';

part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  late final SearchRepository repository;

  SearchBloc({required AuthenticationBloc bloc}) : super(SearchInitial()) {
    repository = SearchRepository(api: bloc.rutrackerApi);
    on<Search>((event, emit) => _search(event, emit));
    on<SearchByGenre>((event, emit) => _searchByGenre(event, emit));
  }

  _search(Search event, Emitter<SearchState> emit) async {
    try {
      emit(SearchLoading());
      List<QueryResponse>? responds = await repository.searchByText(event.query);
      if (responds != null) {
        emit(SearchLoaded(queryResponse: responds));
      } else {
        emit(const SearchError(message: 'Ошибка поиска'));
      }
    } on Exception {
      emit(const SearchError(message: 'Ошибка поиска'));
    }
  }

  _searchByGenre(SearchByGenre event, Emitter<SearchState> emit) async {
    try {
      emit(SearchLoading());
      List<QueryResponse>? responds = await repository.searchByGenre(event.categories);
      if (responds != null) {
        emit(SearchLoaded(queryResponse: responds));
      } else {
        emit(const SearchError(message: 'Ошибка поиска'));
      }
    } on Exception {
      emit(const SearchError(message: 'Ошибка поиска'));
    }
  }
}
