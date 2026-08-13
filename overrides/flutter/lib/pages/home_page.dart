import 'package:flutter/material.dart';
import 'package:flutter_hbb/pages/chat_page.dart';
import 'package:flutter_hbb/pages/server_page.dart';
import 'package:flutter_hbb/pages/settings_page.dart';
import '../common.dart';
import '../webclient_theme.dart';
import '../widgets/overlay.dart';
import 'connection_page.dart';

abstract class PageShape extends Widget {
  final String title = "";
  final Icon icon = Icon(null);
  final List<Widget> appBarActions = [];
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _selectedIndex = 0;
  final List<PageShape> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.add(ConnectionPage());
    if (isAndroid) {
      _pages.addAll([chatPage, ServerPage()]);
    }
    _pages.add(SettingsPage());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (_selectedIndex != 0) {
            setState(() {
              _selectedIndex = 0;
            });
          } else {
            return true;
          }
          return false;
        },
        child: Scaffold(
          backgroundColor: MyTheme.grayBg,
          appBar: AppBar(
            centerTitle: true,
            title: Text("RustDesk"),
            actions: _pages.elementAt(_selectedIndex).appBarActions,
          ),
          bottomNavigationBar: BottomNavigationBar(
            key: navigationBarKey,
            items: _pages
                .map((page) =>
                    BottomNavigationBarItem(icon: page.icon, label: page.title))
                .toList(),
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: MyTheme.accent,
            unselectedItemColor: MyTheme.darkGray,
            onTap: (index) => setState(() {
              if (index == 1 && _selectedIndex != index) {
                hideChatIconOverlay();
                hideChatWindowOverlay();
              }
              _selectedIndex = index;
            }),
          ),
          body: _pages.elementAt(_selectedIndex),
        ));
  }
}

class WebHomePage extends StatelessWidget {
  final connectionPage = ConnectionPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebClientTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: WebClientTheme.surface,
            border: Border(
              bottom: BorderSide(color: WebClientTheme.border),
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1160),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: WebClientTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.desktop_windows_rounded,
                        size: 20,
                        color: WebClientTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Text(
                      'RustDesk',
                      style: TextStyle(
                        color: WebClientTheme.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: WebClientTheme.background,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: WebClientTheme.border),
                      ),
                      child: Text(
                        'WEB CLIENT V1',
                        style: TextStyle(
                          color: WebClientTheme.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ...connectionPage.appBarActions,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: connectionPage,
    );
  }
}
