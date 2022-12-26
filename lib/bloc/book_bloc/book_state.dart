part of 'book_bloc.dart';

abstract class BookState extends Equatable {
  const BookState();

  @override
  List<Object> get props => [];
}

class BookInitial extends BookState {}

class BookLoading extends BookState {}

class BookLoaded extends BookState {
  final List<Book> books;

  const BookLoaded({required this.books});
}

class BookUpdated extends BookState {
  final List<Book> books;

  const BookUpdated({required this.books});
}

class DBBookLoaded extends BookState {
  final Book book;

  const DBBookLoaded({required this.book});
}

class BookError extends BookState {
  final String message;

  const BookError({required this.message});
}