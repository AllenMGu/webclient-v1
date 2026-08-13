import 'package:flutter/material.dart';
import 'package:flutter_hbb/pages/file_manager_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:convert';
import '../common.dart';
import '../models/model.dart';
import '../webclient_theme.dart';
import 'home_page.dart';
import 'remote_page.dart';
import 'settings_page.dart';
import 'scan_page.dart';
import 'web_settings_page.dart';

enum _PeerSection { recent, favorites, addressBook, devices }

class _WebPeer {
  final Map<String, dynamic> raw;
  final String id;
  final String username;
  final String hostname;
  final String platform;
  final String alias;
  final List<String> tags;
  final bool online;
  final int lastOnlineTime;
  final int lastConnected;
  final bool favorite;
  final bool addressBook;
  final List<String> addressBooks;
  final bool managed;

  _WebPeer.fromJson(Map<String, dynamic> json)
    : raw = Map<String, dynamic>.from(json),
      id = json['id'] ?? '',
      username = json['username'] ?? '',
      hostname = json['hostname'] ?? '',
      platform = json['platform'] ?? '',
      alias = json['alias'] ?? '',
      tags = (json['tags'] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .toList(),
      online = json['online'] == true,
      lastOnlineTime = (json['last_online_time'] as num? ?? 0).toInt(),
      lastConnected = (json['last_connected'] as num? ?? 0).toInt(),
      favorite = json['favorite'] == true,
      addressBook = json['address_book'] == true,
      addressBooks = (json['address_books'] as List<dynamic>? ?? [])
          .map((book) => book.toString())
          .toList(),
      managed = json['managed'] == true;

  _WebPeer forAddressBook(String guid) {
    final allDetails = raw['address_book_details'];
    if (allDetails is! Map) return this;
    final detail = allDetails[guid];
    if (detail is! Map) return this;
    return _WebPeer.fromJson({
      ...raw,
      'username': detail['username'] ?? username,
      'hostname': detail['hostname'] ?? hostname,
      'platform': detail['platform'] ?? platform,
      'alias': detail['alias'] ?? alias,
      'tags': detail['tags'] ?? <dynamic>[],
      'hash': detail['hash'] ?? '',
    });
  }

  String get title => alias.isNotEmpty
      ? alias
      : hostname.isNotEmpty
      ? hostname
      : id;

  String get subtitle {
    final identity = username.isNotEmpty && hostname.isNotEmpty
        ? '$username@$hostname'
        : hostname.isNotEmpty
        ? hostname
        : username;
    return identity.isEmpty || identity == title ? id : '$id · $identity';
  }

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return [
      id,
      username,
      hostname,
      platform,
      alias,
      ...tags,
    ].join(' ').toLowerCase().contains(needle);
  }
}

class _WebAddressBook {
  final String guid;
  final String name;
  final String owner;
  final int rule;
  final List<String> tags;

  _WebAddressBook.fromJson(Map<String, dynamic> json)
    : guid = json['guid'] ?? '',
      name = json['name'] ?? '',
      owner = json['owner'] ?? '',
      rule = (json['rule'] as num? ?? 0).toInt(),
      tags = (json['tags'] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .where((tag) => tag.isNotEmpty)
          .toList();
}

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
  final _peerSearchController = TextEditingController();
  final Set<String> _selectedPeers = <String>{};
  _PeerSection _peerSection = _PeerSection.recent;
  bool _searchVisible = false;
  bool _selectionMode = false;
  bool _gridView = true;
  String? _selectedAddressBook;
  String? _selectedAddressBookTag;
  var _updateUrl = '';

  @override
  void initState() {
    super.initState();
    if (!isAndroid) {
      _gridView = FFI.getByName('option', 'webclient-peer-view') != 'list';
    }
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
        child: Column(children: [getUpdateUI(), getSearchBarUI(), getPeers()]),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
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
                    translate(
                      'Connect to another device using its RustDesk ID.',
                    ),
                    style: TextStyle(
                      color: WebClientTheme.muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  getSearchBarUI(),
                  const SizedBox(height: 30),
                  getPeerNavigation(),
                  if (_searchVisible) ...[
                    const SizedBox(height: 12),
                    getPeerSearch(),
                  ],
                  if (_selectionMode && _selectedPeers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    getSelectionActions(),
                  ],
                  const SizedBox(height: 14),
                  getPeers(),
                ],
              ),
            ),
          ),
        );
      },
    );
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
                      style: TextStyle(
                        color: WebClientTheme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      translate('Enter the ID shown on the remote device.'),
                      style: TextStyle(
                        color: WebClientTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final field = TextField(
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  style: TextStyle(
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
                    prefixIcon: Icon(
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
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _peerSearchController.dispose();
    super.dispose();
  }

  Widget getPlatformImage(String platform) {
    platform = platform.toLowerCase();
    if (platform == 'mac os')
      platform = 'mac';
    else if (platform != 'linux' && platform != 'android')
      platform = 'win';
    return Image.asset('assets/$platform.png', width: 24, height: 24);
  }

  Widget getPeerNavigation() {
    final tabs = <Widget>[
      _sectionButton(_PeerSection.recent, Icons.history_rounded, 'Recent'),
      _sectionButton(_PeerSection.favorites, Icons.star_rounded, 'Favorites'),
      _sectionButton(
        _PeerSection.addressBook,
        Icons.contacts_outlined,
        'Address Book',
      ),
      _sectionButton(
        _PeerSection.devices,
        Icons.devices_other_outlined,
        'Devices',
      ),
    ];
    final tools = <Widget>[
      _toolButton(
        _searchVisible ? Icons.search_off_rounded : Icons.search_rounded,
        'Search',
        () => setState(() {
          _searchVisible = !_searchVisible;
          if (!_searchVisible) _peerSearchController.clear();
        }),
        active: _searchVisible,
      ),
      _toolButton(
        _selectionMode
            ? Icons.check_box_rounded
            : Icons.check_box_outline_blank_rounded,
        'Select',
        () => setState(() {
          _selectionMode = !_selectionMode;
          if (!_selectionMode) _selectedPeers.clear();
        }),
        active: _selectionMode,
      ),
      _toolButton(
        _gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
        _gridView ? 'List view' : 'Grid view',
        () {
          setState(() => _gridView = !_gridView);
          FFI.setByName(
            'option',
            json.encode({
              'name': 'webclient-peer-view',
              'value': _gridView ? 'grid' : 'list',
            }),
          );
        },
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: tabs),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: tools),
            ],
          );
        }
        return Row(children: [...tabs, const Spacer(), ...tools]);
      },
    );
  }

  Widget _sectionButton(_PeerSection section, IconData icon, String label) {
    final selected = _peerSection == section;
    return Tooltip(
      message: translate(label),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() {
          _peerSection = section;
          _selectedPeers.clear();
          if (section != _PeerSection.addressBook) {
            _selectedAddressBookTag = null;
          }
        }),
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? WebClientTheme.accent.withOpacity(0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              bottom: BorderSide(
                color: selected ? WebClientTheme.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? WebClientTheme.accent : WebClientTheme.muted,
              ),
              const SizedBox(width: 7),
              Text(
                translate(label),
                style: TextStyle(
                  color: selected
                      ? WebClientTheme.accent
                      : WebClientTheme.muted,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    bool active = false,
  }) {
    return IconButton(
      tooltip: translate(label),
      splashRadius: 20,
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 20,
        color: active ? WebClientTheme.accent : WebClientTheme.muted,
      ),
    );
  }

  Widget getPeerSearch() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _peerSearchController,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: translate('Search ID, alias, device, user or tag'),
          prefixIcon: const Icon(Icons.search_rounded, size: 19),
          suffixIcon: _peerSearchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: translate('Clear'),
                  onPressed: () => setState(_peerSearchController.clear),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
        ),
      ),
    );
  }

  Widget getSelectionActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: WebClientTheme.surface,
        border: Border.all(color: WebClientTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedPeers.length} ${translate('selected')}',
            style: TextStyle(
              color: WebClientTheme.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _setSelectedFavorites(true),
            icon: const Icon(Icons.star_outline_rounded, size: 18),
            label: Text(translate('Favorite')),
          ),
          if (_peerSection == _PeerSection.favorites)
            TextButton.icon(
              onPressed: () => _setSelectedFavorites(false),
              icon: const Icon(Icons.star_border_rounded, size: 18),
              label: Text(translate('Unfavorite')),
            ),
          if (_peerSection == _PeerSection.recent)
            TextButton.icon(
              onPressed: _clearSelectedRecent,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(translate('Remove from recent')),
            ),
        ],
      ),
    );
  }

  List<_WebPeer> _peerCatalog() {
    if (isAndroid) {
      return FFI
          .peers()
          .map(
            (peer) => _WebPeer.fromJson({
              'id': peer.id,
              'username': peer.username,
              'hostname': peer.hostname,
              'platform': peer.platform,
              'last_connected': 1,
            }),
          )
          .toList();
    }
    try {
      final value = FFI.getByName('peer_catalog');
      if (value.isEmpty) return [];
      return (json.decode(value) as List<dynamic>)
          .map((peer) => _WebPeer.fromJson(peer as Map<String, dynamic>))
          .where((peer) => peer.id.isNotEmpty)
          .toList();
    } catch (error) {
      debugPrint('peer_catalog: $error');
      return [];
    }
  }

  List<_WebAddressBook> _addressBookCatalog() {
    if (isAndroid) return [];
    try {
      final value = FFI.getByName('address_book_catalog');
      if (value.isEmpty) return [];
      return (json.decode(value) as List<dynamic>)
          .map((book) => _WebAddressBook.fromJson(book as Map<String, dynamic>))
          .where((book) => book.guid.isNotEmpty)
          .toList();
    } catch (error) {
      debugPrint('address_book_catalog: $error');
      return [];
    }
  }

  String? _effectiveAddressBook(List<_WebAddressBook> books) {
    if (books.isEmpty) return null;
    if (books.any((book) => book.guid == _selectedAddressBook)) {
      return _selectedAddressBook;
    }
    return books.first.guid;
  }

  List<_WebPeer> _visiblePeers() {
    final query = _peerSearchController.text;
    final books = _addressBookCatalog();
    final selectedBook = _effectiveAddressBook(books);
    return _peerCatalog().map((peer) {
      if (_peerSection == _PeerSection.addressBook && selectedBook != null) {
        return peer.forAddressBook(selectedBook);
      }
      return peer;
    }).where((peer) {
      final inSection = _peerSection == _PeerSection.recent
          ? peer.lastConnected > 0
          : _peerSection == _PeerSection.favorites
          ? peer.favorite
          : _peerSection == _PeerSection.addressBook
          ? peer.addressBook &&
                (selectedBook == null || peer.addressBooks.contains(selectedBook)) &&
                (_selectedAddressBookTag == null ||
                    peer.tags.contains(_selectedAddressBookTag))
          : peer.managed;
      return inSection && peer.matches(query);
    }).toList();
  }

  Widget getPeers() {
    final peers = _visiblePeers();
    if (_peerSection == _PeerSection.addressBook && !isAndroid) {
      return _addressBookView(peers);
    }
    if (peers.isEmpty && !isAndroid) return _emptyPeerState();
    return _peerResults(peers);
  }

  Widget _peerResults(List<_WebPeer> peers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_gridView) {
          return Column(
            children: peers
                .map(
                  (peer) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _peerCard(peer, constraints.maxWidth, true),
                  ),
                )
                .toList(),
          );
        }
        const space = 12.0;
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 640
            ? 2
            : 1;
        final width = (constraints.maxWidth - space * (columns - 1)) / columns;
        return Wrap(
          spacing: space,
          runSpacing: space,
          children: peers.map((peer) => _peerCard(peer, width, false)).toList(),
        );
      },
    );
  }

  Widget _addressBookView(List<_WebPeer> peers) {
    final books = _addressBookCatalog();
    if (books.isEmpty) return _emptyPeerState();
    final selectedGuid = _effectiveAddressBook(books);
    final selected = books.firstWhere((book) => book.guid == selectedGuid);
    final tags = selected.tags.toSet().toList()..sort();

    final selector = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WebClientTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WebClientTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: selectedGuid,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: translate('Address Book'),
              prefixIcon: const Icon(Icons.contacts_outlined, size: 19),
            ),
            items: books
                .map(
                  (book) => DropdownMenuItem<String>(
                    value: book.guid,
                    child: Text(
                      book.owner == book.name || book.owner.isEmpty
                          ? book.name
                          : '${book.name} · ${book.owner}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _selectedAddressBook = value;
              _selectedAddressBookTag = null;
              _selectedPeers.clear();
            }),
          ),
          const SizedBox(height: 16),
          Text(
            translate('Tags'),
            style: TextStyle(
              color: WebClientTheme.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          _addressBookTag('All', null),
          if (tags.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                translate('No tags'),
                style: TextStyle(
                  color: WebClientTheme.muted,
                  fontSize: 12,
                ),
              ),
            ),
          ...tags.map((tag) => _addressBookTag(tag, tag)),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final results = peers.isEmpty ? _emptyPeerState() : _peerResults(peers);
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [selector, const SizedBox(height: 12), results],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 220, child: selector),
            const SizedBox(width: 14),
            Expanded(child: results),
          ],
        );
      },
    );
  }

  Widget _addressBookTag(String label, String? tag) {
    final selected = _selectedAddressBookTag == tag;
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: () => setState(() {
        _selectedAddressBookTag = tag;
        _selectedPeers.clear();
      }),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? WebClientTheme.accent.withOpacity(0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          translate(label),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? WebClientTheme.accent : WebClientTheme.muted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _emptyPeerState() {
    final data = _peerSection == _PeerSection.recent
        ? ['No recent sessions', 'Devices you connect to will appear here.']
        : _peerSection == _PeerSection.favorites
        ? ['No favorites', 'Use the star action to keep devices here.']
        : _peerSection == _PeerSection.addressBook
        ? [
            'Address book is empty',
            'Sign in to sync devices from the API address book.',
          ]
        : [
            'No registered devices',
            'Devices signed in to this account will appear here.',
          ];
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
          Icon(
            Icons.devices_other_outlined,
            color: WebClientTheme.muted,
            size: 29,
          ),
          const SizedBox(height: 10),
          Text(
            translate(data[0]),
            style: TextStyle(
              color: WebClientTheme.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            translate(data[1]),
            textAlign: TextAlign.center,
            style: TextStyle(color: WebClientTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _peerCard(_WebPeer peer, double width, bool listMode) {
    final selected = _selectedPeers.contains(peer.id);
    return SizedBox(
      width: width,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? WebClientTheme.accent : WebClientTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_selectionMode) {
              setState(() {
                selected
                    ? _selectedPeers.remove(peer.id)
                    : _selectedPeers.add(peer.id);
              });
            } else {
              _connectPeer(peer);
            }
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              listMode ? 11 : 15,
              6,
              listMode ? 11 : 15,
            ),
            child: Row(
              children: [
                if (_selectionMode) ...[
                  Checkbox(
                    value: selected,
                    onChanged: (_) => setState(() {
                      selected
                          ? _selectedPeers.remove(peer.id)
                          : _selectedPeers.add(peer.id);
                    }),
                  ),
                  const SizedBox(width: 4),
                ],
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: str2color('${peer.id}${peer.platform}', 0x24),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: getPlatformImage(peer.platform),
                    ),
                    if (peer.managed)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: peer.online
                                ? const Color(0xFF24A148)
                                : WebClientTheme.muted,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: WebClientTheme.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              peer.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: WebClientTheme.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (peer.favorite) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Color(0xFFF5A623),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        peer.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: WebClientTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (peer.tags.isNotEmpty || peer.managed) ...[
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: [
                            if (peer.managed)
                              _peerBadge(
                                peer.online ? 'Online' : _lastSeen(peer),
                                peer.online
                                    ? const Color(0xFFE7F6EA)
                                    : WebClientTheme.background,
                                peer.online
                                    ? const Color(0xFF147D32)
                                    : WebClientTheme.muted,
                              ),
                            ...peer.tags
                                .take(2)
                                .map(
                                  (tag) => _peerBadge(
                                    tag,
                                    WebClientTheme.background,
                                    WebClientTheme.muted,
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_selectionMode) _peerMenu(peer),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _peerBadge(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        translate(label),
        style: TextStyle(color: foreground, fontSize: 10),
      ),
    );
  }

  String _lastSeen(_WebPeer peer) {
    if (peer.lastOnlineTime <= 0) return 'Offline';
    final seconds =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - peer.lastOnlineTime;
    if (seconds < 120) return 'Online';
    if (seconds < 3600) return '${seconds ~/ 60}m ago';
    if (seconds < 86400) return '${seconds ~/ 3600}h ago';
    return '${seconds ~/ 86400}d ago';
  }

  Widget _peerMenu(_WebPeer peer) {
    return PopupMenuButton<String>(
      tooltip: translate('More'),
      icon: Icon(Icons.more_vert, color: WebClientTheme.muted, size: 20),
      onSelected: (value) {
        if (value == 'connect') _connectPeer(peer);
        if (value == 'favorite') _setFavorite(peer.id, !peer.favorite);
        if (value == 'remove_recent') _clearRecent([peer.id]);
        if (value == 'file') connect(peer.id, isFileTransfer: true);
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'connect',
          child: _menuAction(Icons.desktop_windows_outlined, 'Connect'),
        ),
        PopupMenuItem<String>(
          value: 'favorite',
          child: _menuAction(
            peer.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
            peer.favorite ? 'Unfavorite' : 'Favorite',
          ),
        ),
        if (peer.lastConnected > 0)
          PopupMenuItem<String>(
            value: 'remove_recent',
            child: _menuAction(
              Icons.delete_outline_rounded,
              'Remove from recent',
            ),
          ),
        if (isAndroid)
          PopupMenuItem<String>(
            value: 'file',
            child: _menuAction(Icons.file_present_outlined, 'Transfer File'),
          ),
      ],
    );
  }

  void _connectPeer(_WebPeer peer) {
    if (_peerSection == _PeerSection.addressBook) {
      final books = _addressBookCatalog();
      final selectedBook = _effectiveAddressBook(books);
      if (selectedBook != null) {
        FFI.setByName(
          'address_book_activate',
          json.encode({'id': peer.id, 'guid': selectedBook}),
        );
      }
    }
    connect(peer.id);
  }

  Widget _menuAction(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: WebClientTheme.muted),
        const SizedBox(width: 11),
        Text(translate(label)),
      ],
    );
  }

  void _setFavorite(String id, bool favorite) {
    FFI.setByName(
      'peer_favorite',
      json.encode({'id': id, 'favorite': favorite}),
    );
    setState(() {});
  }

  void _setSelectedFavorites(bool favorite) {
    for (final id in _selectedPeers) {
      FFI.setByName(
        'peer_favorite',
        json.encode({'id': id, 'favorite': favorite}),
      );
    }
    setState(_selectedPeers.clear);
  }

  void _clearSelectedRecent() => _clearRecent(_selectedPeers.toList());

  void _clearRecent(List<String> ids) {
    FFI.setByName('clear_recent', json.encode(ids));
    for (final id in ids) {
      removePreference(id);
    }
    setState(_selectedPeers.clear);
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
                    ),
                  ]
                : <PopupMenuItem<String>>[]) +
            [
              PopupMenuItem<String>(
                child: _menuItem(Icons.settings_outlined, 'Settings'),
                value: 'settings',
              ),
              PopupMenuItem<String>(
                child: _menuItem(Icons.dns_outlined, 'ID/Relay Server'),
                value: 'server',
              ),
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
                    ),
                  ]) +
            [
              PopupMenuItem<String>(
                child: _menuItem(Icons.info_outline, 'About RustDesk'),
                value: 'about',
              ),
            ];
      },
      onSelected: (value) {
        if (value == 'settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WebSettingsPage()),
          );
        }
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
            MaterialPageRoute(builder: (BuildContext context) => ScanPage()),
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
