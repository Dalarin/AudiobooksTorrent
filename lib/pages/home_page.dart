import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rutracker_app/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:rutracker_app/bloc/book_bloc/book_bloc.dart';
import 'package:rutracker_app/generated/l10n.dart';
import 'package:rutracker_app/providers/enums.dart';
import 'package:rutracker_app/repository/book_repository.dart';
import 'package:rutracker_app/widgets/book_list.dart';

class HomePage extends StatelessWidget {
  final AuthenticationBloc authenticationBloc;

  const HomePage({
    Key? key,
    required this.authenticationBloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
      ),
      extendBody: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: _homePageContent(context),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _homePageContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        _title(S.of(context).recentlyListened),
        const SizedBox(height: 15),
        _listeningBooksListBuilder(context, authenticationBloc),
        const SizedBox(height: 15),
        _title(S.of(context).favorite),
        const SizedBox(height: 15),
        _favoriteBooksListBuilder(context, authenticationBloc),
      ],
    );
  }

  Widget _listeningBooksListBuilder(
    BuildContext context,
    AuthenticationBloc authenticationBloc,
  ) {
    return BlocProvider<BookBloc>(
      create: (context) {
        return BookBloc(
          repository: BookRepository(api: authenticationBloc.rutrackerApi),
        );
      },
      child: Builder(
        builder: (context) {
          return BlocConsumer<BookBloc, BookState>(
            bloc: context.read<BookBloc>()..add(GetDownloadedBooks()),
            listener: (context, state) {
              if (state is BookError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is BookLoaded) {
                return ElementsList(
                  list: state.books,
                  bloc: authenticationBloc,
                  emptyListText: S.of(context).emptyListeningList,
                );
              } else if (state is BookLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return ElementsList(
                list: const [],
                bloc: authenticationBloc,
                emptyListText: S.of(context).emptyListeningList,
              );
            },
          );
        },
      ),
    );
  }

  Widget _favoriteBooksListBuilder(
    BuildContext context,
    AuthenticationBloc authenticationBloc,
  ) {
    return BlocProvider<BookBloc>(
      create: (context) {
        return BookBloc(
          repository: BookRepository(
            api: authenticationBloc.rutrackerApi,
          ),
        );
      },
      child: Builder(
        builder: (context) {
          return BlocConsumer<BookBloc, BookState>(
            bloc: context.read<BookBloc>()..add(const GetFavoritesBooks(sortOrder: Sort.standart, limit: 3, filter: Filter.values)),
            listener: (context, state) {
              if (state is BookError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is BookLoaded) {
                return ElementsList(
                  list: state.books,
                  emptyListText: S.of(context).emptyFavoriteList,
                  bloc: authenticationBloc,
                );
              } else if (state is BookLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                return ElementsList(
                  list: const [],
                  emptyListText: S.of(context).emptyFavoriteList,
                  bloc: authenticationBloc,
                );
              }
            },
          );
        },
      ),
    );
  }
}
