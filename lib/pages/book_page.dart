import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rutracker_app/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:rutracker_app/bloc/book_bloc/book_bloc.dart';
import 'package:rutracker_app/bloc/torrent_bloc/torrent_bloc.dart';
import 'package:rutracker_app/generated/l10n.dart';
import 'package:rutracker_app/models/book.dart';
import 'package:rutracker_app/pages/comments_page.dart';
import 'package:rutracker_app/widgets/downloading_button.dart';
import 'package:rutracker_app/widgets/image.dart';

class BookPage extends StatefulWidget {
  final Book book;
  final List<Book> books;
  final AuthenticationBloc authenticationBloc;

  const BookPage({
    Key? key,
    required this.book,
    required this.books,
    required this.authenticationBloc,
  }) : super(key: key);

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  late final TextEditingController titleController;
  late final TextEditingController imageController;

  @override
  void initState() {
    titleController = TextEditingController();
    titleController.text = widget.book.title;
    imageController = TextEditingController();
    imageController.text = widget.book.image;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TorrentBloc(
        api: widget.authenticationBloc.rutrackerApi,
      ),
      child: BlocBuilder<BookBloc, BookState>(
        builder: (context, state) {
          return SafeArea(
            child: Scaffold(
              extendBodyBehindAppBar: true,
              appBar: _appBar(context, widget.book, widget.books),
              body: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _bookPageContent(
                      context,
                      widget.authenticationBloc,
                      widget.book,
                      widget.books,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bookPageContent(BuildContext context, AuthenticationBloc bloc, Book book, List<Book> books) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            _coverGradientBox(context, book),
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.57,
              ),
              width: MediaQuery.of(context).size.width * 0.7,
              child: DownloadingButton(book: book, bookList: books),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _aboutSection(context, book),
        const SizedBox(height: 15),
        _descriptionSection(context, book),
        const SizedBox(height: 15),
        _additionalActions(context, book, books, bloc),
      ],
    );
  }

  Widget _additionalActions(
    BuildContext context,
    Book book,
    List<Book> list,
    AuthenticationBloc bloc,
  ) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.15,
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.comment),
            title: Text(S.of(context).comments),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommentsPage(
                    bloc: bloc,
                    book: book,
                  ),
                ),
              );
            },
          ),
          Tooltip(
            message: S.of(context).bookSettingsTooltip,
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.settings),
              title: Text(S.of(context).bookSettings),
              enabled: book.isFavorite || book.isDownloaded,
              onTap: () => _showSettingsDialog(context, book, list),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutElement({
    required BuildContext context,
    required String title,
    required String text,
    required CrossAxisAlignment alignment,
    required TextAlign textAlign,
  }) {
    return Tooltip(
      message: text,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.33 - 8.0,
        child: Column(
          crossAxisAlignment: alignment,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              text,
              textAlign: textAlign,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }

  Widget _aboutSection(BuildContext context, Book book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _aboutElement(
            context: context,
            title: S.of(context).genre,
            text: book.genre,
            textAlign: TextAlign.start,
            alignment: CrossAxisAlignment.start,
          ),
          _aboutElement(
            context: context,
            title: S.of(context).executor,
            text: book.executor,
            textAlign: TextAlign.center,
            alignment: CrossAxisAlignment.center,
          ),
          _aboutElement(
            context: context,
            title: S.of(context).audio,
            text: book.audio,
            textAlign: TextAlign.end,
            alignment: CrossAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  Widget _descriptionSection(BuildContext context, Book book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SelectableText(
        book.description,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          height: 1.5,
        ),
      ),
    );
  }

  Widget _coverGradientBox(BuildContext context, Book book) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.6,
      padding: const EdgeInsets.symmetric(vertical: 15),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: _coverBoxContent(
        context: context,
        book: book,
        width: width,
        height: height,
      ),
    );
  }

  Widget _coverBoxContent({
    required BuildContext context,
    required Book book,
    required double width,
    required double height,
  }) {
    ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            _showFullImage(
              context: context,
              book: book,
              width: width,
              height: height,
            );
          },
          child: CustomImage(
            book: book,
            width: width * 0.7,
            height: height * 0.35,
            borderRadius: 20,
          ),
        ),
        const SizedBox(height: 15),
        Tooltip(
          message: book.title,
          child: Text(
            book.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Tooltip(
          message: book.author,
          child: Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        label: Text(hint),
      ),
    );
  }

  AppBar _appBar(
    BuildContext context,
    Book book,
    List<Book> books,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      actions: [
        IconButton(
          onPressed: () {
            book.isFavorite = !book.isFavorite;
            final bloc = context.read<BookBloc>();
            bloc.add(UpdateBook(book: book, books: books));
          },
          isSelected: book.isFavorite,
          icon: const Icon(Icons.favorite_border_rounded),
          selectedIcon: const Icon(Icons.favorite_rounded),
        ),
        IconButton(
          onPressed: () => _showMoreInfoDialog(context, book),
          icon: const Icon(Icons.info_outline_rounded),
        ),
      ],
    );
  }

  void _showFullImage({
    required BuildContext context,
    required Book book,
    required double width,
    required double height,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: CustomImage(
            book: book,
            width: width,
            height: height * 0.4,
            borderRadius: 20,
          ),
        );
      },
    );
  }

  void _showMoreInfoDialog(BuildContext context, Book book) {
    showDialog<void>(
      context: context,
      builder: (BuildContext _) {
        return AlertDialog(
          title: Text(S.of(context).detailedInformation),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.of(context).releaseYear(book.releaseYear)),
              const Divider(),
              Text(S.of(context).series(book.series)),
              const Divider(),
              Text(S.of(context).bookNumber(book.bookNumber)),
              const Divider(),
              Text(S.of(context).bitrate(book.bitrate)),
              const Divider(),
              Text(S.of(context).bookSize(book.size)),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context, Book book, List<Book> books) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(S.of(context).settings),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _textField(
                context: context,
                controller: titleController,
                hint: S.of(context).bookTitle,
              ),
              const SizedBox(height: 15),
              _textField(
                context: context,
                controller: imageController,
                hint: S.of(context).bookLinkImage,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).save),
              onPressed: () {
                final bloc = context.read<BookBloc>();
                book.title = titleController.text;
                book.image = imageController.text;
                bloc.add(UpdateBook(book: book, books: books));
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
