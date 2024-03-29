part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<QueryResponse> queryResponse;

  const SearchLoaded({required this.queryResponse});
}


class SearchError extends SearchState {
  final String message;

  const SearchError({required this.message});
}
