import 'package:flutter/material.dart';
import 'package:flutter_hbb/pages/file_manager_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../common.dart';
import '../models/model.dart';
import '../webclient_theme.dart';
import 'home_page.dart';
import 'remote_page.dart';
import 'settings_page.dart';
import 'scan_page.dart';

class ConnectionPage extends StatefulWidget implements PageShape {
  ConnectionPage({Key? key}) : super(key: key);

  @override
  final icon = Icon(Icons.connected_tv);

  @override
  final title = translate("Connection");

  @override
  final appBarActions = !isAndroid ? <Widget>[WebMenu()] : <Widget>[];

  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final _idController = TextEditingController();
  var _updateUrl = '';
  var _menuPos;

  @override
  void initState() {
    super.initState();
    if (isAndroid) {
      Timer(Duration(seconds: 5), () {
        _updateUrl = FFI.getByName('software_update_url');
        if (_updateUrl.isNotEmpty) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<FfiModel>(context);
    if (_idController.text.isEmpty) _idController.text = FFI.getId();

    if (isAndroid) {
      return SingleChildScrollView(
        child: Column(
          children: [getUpdateUI(), getSearchBarUI(), getPeers()],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 38, 24, 48),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getUpdateUI(),
                Text(
                  translate('Remote Desktop'),
                  style: Theme.of(context).textTheme.headline5,
                ),
                const SizedBox(height: 7),
                Text(
                  translate('Connect to another device using its RustDesk ID.'),
                  style: const TextStyle(
                    color: WebClientTheme.muted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),
                getSearchBarUI(),
                const SizedBox(height: 34),
                Row(
                  children: [
                    Text(
                      translate('Recent Sessions'),
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child:
                            Container(height: 1, color: WebClientTheme.border)),
                  ],
                ),
                const SizedBox(height: 16),
                getPeers(),
              ],
            ),
          ),
        ),
      );
    });
  }

  void onConnect() {
    var id = _idController.text.trim();
    connect(id);
  }

  void connect(String id, {bool isFileTransfer = false}) async {
    if (id == '') return;
    id = id.replaceAll(' ', '');
    if (isFileTransfer) {
      if (!await PermissionManager.check("file")) {
        if (!await PermissionManager.request("file")) {
          return;
        }
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => FileManagerPage(id: id),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => RemotePage(id: id),
        ),
      );
    }
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  Widget getUpdateUI() {
    return _updateUrl.isEmpty
        ? SizedBox(height: 0)
        : InkWell(
            onTap: () async {
              final url = _updateUrl + '.apk';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
            child: Container(
              alignment: AlignmentDirectional.center,
              width: double.infinity,
              color: Colors.pinkAccent,
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                translate('Download new version'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
  }

  Widget getSearchBarUI() {
    if (isAndroid) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: TextField(
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          controller: _idController,
          onSubmitted: (_) => onConnect(),
          decoration: InputDecoration(
            labelText: translate('Remote ID'),
            suffixIcon: IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: onConnect,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: WebClientTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.screen_share_outlined,
                    color: WebClientTheme.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translate('Control Remote Desktop'),
                      style: const TextStyle(
                        color: WebClientTheme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      translate('Enter the ID shown on the remote device.'),
                      style: const TextStyle(
                        color: WebClientTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final field = TextField(
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                style: const TextStyle(
                  color: WebClientTheme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                ),
                controller: _idController,
                onSubmitted: (_) => onConnect(),
                decoration: InputDecoration(
                  labelText: translate('Remote ID'),
                  hintText: '123 456 789',
                  prefixIcon: const Icon(
                    Icons.tag_rounded,
                    size: 20,
                    color: WebClientTheme.muted,
                  ),
                ),
              );
              final button = SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onConnect,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                  label: Text(translate('Connect')),
                ),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [field, const SizedBox(height: 12), button],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: field),
                  const SizedBox(width: 12),
                  button,
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Widget getPlatformImage(String platform) {
    platform = platform.toLowerCase();
    if (platform == 'mac os')
      platform = 'mac';
    else if (platform != 'linux' && platform != 'android') platform = 'win';
    return Image.asset('assets/$platform.png', width: 24, height: 24);
  }

  Widget getPeers() {
    var peers = FFI.peers();
    if (peers.isEmpty && !isAndroid) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 24),
        decoration: BoxDecoration(
          color: WebClientTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WebClientTheme.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.devices_other_outlined,
              color: WebClientTheme.muted,
              size: 29,
            ),
            const SizedBox(height: 10),
            Text(
              translate('No recent sessions'),
              style: const TextStyle(
                color: WebClientTheme.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              translate('Devices you connect to will appear here.'),
              style: const TextStyle(color: WebClientTheme.muted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      const space = 12.0;
      final columns = constraints.maxWidth >= 980
          ? 3
          : constraints.maxWidth >= 640
              ? 2
              : 1;
      final width = (constraints.maxWidth - space * (columns - 1)) / columns;
      final cards = <Widget>[];
      peers.forEach((p) {
        cards.add(SizedBox(
          width: width,
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: !isDesktop ? () => connect('${p.id}') : null,
              onDoubleTap: isDesktop ? () => connect('${p.id}') : null,
              onLongPress: () {
                final box = context.findRenderObject() as RenderBox;
                final point = box.localToGlobal(Offset(width / 2, 80));
                _menuPos = RelativeRect.fromLTRB(
                    point.dx, point.dy, point.dx, point.dy);
                showPeerMenu(context, p.id);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 8, 15),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: str2color('${p.id}${p.platform}', 0x24),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: getPlatformImage('${p.platform}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: WebClientTheme.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p.username}@${p.hostname}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: WebClientTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: translate('More'),
                      icon: const Icon(
                        Icons.more_vert,
                        color: WebClientTheme.muted,
                        size: 20,
                      ),
                      onPressed: () {
                        final box = context.findRenderObject() as RenderBox;
                        final point = box.localToGlobal(Offset(width - 12, 58));
                        _menuPos = RelativeRect.fromLTRB(
                            point.dx, point.dy, point.dx, point.dy);
                        showPeerMenu(context, p.id);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
      });
      return Wrap(spacing: space, runSpacing: space, children: cards);
    });
  }

  void showPeerMenu(BuildContext context, String id) async {
    var value = await showMenu(
      context: context,
      position: this._menuPos,
      items: [
            PopupMenuItem<String>(
              child: Text(translate('Remove')),
              value: 'remove',
            )
          ] +
          (!isAndroid
              ? []
              : [
                  PopupMenuItem<String>(
                    child: Text(translate('Transfer File')),
                    value: 'file',
                  )
                ]),
      elevation: 8,
    );
    if (value == 'remove') {
      setState(() => FFI.setByName('remove', '$id'));
      () async {
        removePreference(id);
      }();
    } else if (value == 'file') {
      connect(id, isFileTransfer: true);
    }
  }
}

class WebMenu extends StatefulWidget {
  @override
  _WebMenuState createState() => _WebMenuState();
}

class _WebMenuState extends State<WebMenu> {
  @override
  Widget build(BuildContext context) {
    Provider.of<FfiModel>(context);
    final username = getUsername();
    return PopupMenuButton<String>(
      tooltip: translate('Menu'),
      padding: EdgeInsets.zero,
      offset: const Offset(0, 10),
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: WebClientTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: WebClientTheme.border),
        ),
        child: Icon(
          username == null ? Icons.menu_rounded : Icons.person_outline_rounded,
          size: 20,
          color: WebClientTheme.muted,
        ),
      ),
      itemBuilder: (context) {
        return (isIOS
                ? [
                    PopupMenuItem<String>(
                      child: _menuItem(Icons.qr_code_scanner, 'Scan'),
                      value: 'scan',
                    )
                  ]
                : <PopupMenuItem<String>>[]) +
            [
              PopupMenuItem<String>(
                child: _menuItem(Icons.dns_outlined, 'ID/Relay Server'),
                value: 'server',
              )
            ] +
            (getUrl().contains('admin.rustdesk.com')
                ? <PopupMenuItem<String>>[]
                : [
                    PopupMenuItem<String>(
                      child: _menuItem(
                        username == null ? Icons.login : Icons.logout,
                        username == null ? 'Login' : 'Logout ($username)',
                      ),
                      value: 'login',
                    )
                  ]) +
            [
              PopupMenuItem<String>(
                child: _menuItem(Icons.info_outline, 'About RustDesk'),
                value: 'about',
              )
            ];
      },
      onSelected: (value) {
        if (value == 'server') showServerSettings();
        if (value == 'about') showAbout();
        if (value == 'login') {
          if (username == null) {
            showLogin();
          } else {
            logout();
          }
        }
        if (value == 'scan') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => ScanPage(),
            ),
          );
        }
      },
    );
  }

  Widget _menuItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: WebClientTheme.muted),
        const SizedBox(width: 12),
        Text(translate(label)),
      ],
    );
  }
}
