import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common.dart';
import '../models/model.dart';
import '../webclient_theme.dart';
import 'settings_page.dart';

enum _SettingsSection { general, network, display, account, about }

class WebSettingsPage extends StatefulWidget {
  @override
  _WebSettingsPageState createState() => _WebSettingsPageState();
}

class _WebSettingsPageState extends State<WebSettingsPage> {
  static const _sourceUrl = 'https://github.com/AllenMGu/webclient-v1';
  _SettingsSection _section = _SettingsSection.general;

  late String _theme;
  late String _language;
  late bool _adaptiveBitrate;
  late String _viewStyle;
  late String _imageQuality;
  late bool _showRemoteCursor;
  late bool _enableAudio;
  late bool _enableClipboard;

  late final TextEditingController _idServerController;
  late final TextEditingController _relayServerController;
  late final TextEditingController _apiServerController;
  late final TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    _theme = _option('webclient-theme', 'system');
    _language = _option('webclient-language', 'system');
    _adaptiveBitrate = _boolOption('webclient-adaptive-bitrate', true);
    _viewStyle = _option('webclient-default-view-style', 'shrink');
    _imageQuality = _option('webclient-default-image-quality', 'balanced');
    _showRemoteCursor = _boolOption('webclient-show-remote-cursor', true);
    _enableAudio = _boolOption('webclient-enable-audio', true);
    _enableClipboard = _boolOption('webclient-enable-clipboard', true);
    _idServerController = TextEditingController(
      text: FFI.getByName('option', 'custom-rendezvous-server'),
    );
    _relayServerController = TextEditingController(
      text: FFI.getByName('option', 'relay-server'),
    );
    _apiServerController = TextEditingController(
      text: FFI.getByName('option', 'api-server'),
    );
    _keyController = TextEditingController(
      text: FFI.getByName('option', 'key'),
    );
  }

  String _option(String name, String fallback) {
    final value = FFI.getByName('option', name);
    return value.isEmpty ? fallback : value;
  }

  bool _boolOption(String name, bool fallback) {
    final value = FFI.getByName('option', name);
    if (value.isEmpty) return fallback;
    return value == 'true';
  }

  void _saveOption(String name, Object value) {
    FFI.setByName(
      'option',
      json.encode({'name': name, 'value': value.toString()}),
    );
  }

  void _saveNetwork() {
    _saveOption(
      'custom-rendezvous-server',
      _idServerController.text.trim(),
    );
    _saveOption('relay-server', _relayServerController.text.trim());
    _saveOption('api-server', _apiServerController.text.trim());
    _saveOption('key', _keyController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(translate('Server settings saved'))),
    );
  }

  @override
  void dispose() {
    _idServerController.dispose();
    _relayServerController.dispose();
    _apiServerController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebClientTheme.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: translate('Back'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(translate('Settings')),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 760) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: DropdownButtonFormField<_SettingsSection>(
                    value: _section,
                    items: _SettingsSection.values
                        .map(
                          (section) => DropdownMenuItem(
                            value: section,
                            child: Text(translate(_sectionLabel(section))),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _section = value!),
                  ),
                ),
                Expanded(child: _content()),
              ],
            );
          }
          return Row(
            children: [
              Container(
                width: 220,
                decoration: BoxDecoration(
                  color: WebClientTheme.surface,
                  border: Border(
                    right: BorderSide(color: WebClientTheme.border),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
                  children: _SettingsSection.values
                      .map((section) => _navItem(section))
                      .toList(),
                ),
              ),
              Expanded(child: _content()),
            ],
          );
        },
      ),
    );
  }

  Widget _navItem(_SettingsSection section) {
    final selected = section == _section;
    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: WebClientTheme.accent.withOpacity(0.09),
      selectedColor: WebClientTheme.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(_sectionIcon(section), size: 20),
      title: Text(
        translate(_sectionLabel(section)),
        style: TextStyle(fontWeight: selected ? FontWeight.w600 : null),
      ),
      onTap: () => setState(() => _section = section),
    );
  }

  Widget _content() {
    Widget child;
    switch (_section) {
      case _SettingsSection.network:
        child = _network();
        break;
      case _SettingsSection.display:
        child = _display();
        break;
      case _SettingsSection.account:
        child = _account();
        break;
      case _SettingsSection.about:
        child = _about();
        break;
      default:
        child = _general();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 44),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: child,
        ),
      ),
    );
  }

  Widget _general() {
    return Column(
      children: [
        _panel(
          'Theme',
          ['light', 'dark', 'system']
              .map(
                (value) => RadioListTile<String>(
                  value: value,
                  groupValue: _theme,
                  title: Text(translate(_themeLabel(value))),
                  onChanged: (next) {
                    setState(() => _theme = next!);
                    _saveOption('webclient-theme', next!);
                    FFI.setByName('reload', '');
                  },
                ),
              )
              .toList(),
        ),
        _panel(
          'Language',
          [
            DropdownButtonFormField<String>(
              value: _language,
              items: const [
                DropdownMenuItem(value: 'system', child: Text('跟随系统 / System')),
                DropdownMenuItem(value: 'cn', child: Text('简体中文 (zh-cn)')),
                DropdownMenuItem(value: 'en', child: Text('English (en)')),
              ],
              onChanged: (next) {
                setState(() => _language = next!);
                _saveOption('webclient-language', next == 'system' ? '' : next!);
                FFI.setByName('reload', '');
              },
            ),
          ],
        ),
        _panel(
          'Other',
          [
            SwitchListTile(
              value: _adaptiveBitrate,
              title: Text(translate('Adaptive bitrate')),
              subtitle: Text(
                translate('Use balanced image quality as the connection default.'),
              ),
              onChanged: (value) {
                setState(() => _adaptiveBitrate = value);
                _saveOption('webclient-adaptive-bitrate', value);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _network() {
    return _panel(
      'Network',
      [
        _serverField(_idServerController, 'ID Server'),
        _serverField(_relayServerController, 'Relay Server'),
        _serverField(_apiServerController, 'API Server'),
        _serverField(_keyController, 'Key'),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _saveNetwork,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(translate('Save')),
          ),
        ),
      ],
    );
  }

  Widget _display() {
    return Column(
      children: [
        _panel(
          'Default display mode',
          [
            _radio('Original size', 'original', _viewStyle, (value) {
              setState(() => _viewStyle = value);
              _saveOption('webclient-default-view-style', value);
            }),
            _radio('Fit window', 'shrink', _viewStyle, (value) {
              setState(() => _viewStyle = value);
              _saveOption('webclient-default-view-style', value);
            }),
          ],
        ),
        _panel(
          'Default image quality',
          [
            for (final value in ['best', 'balanced', 'low'])
              _radio(_qualityLabel(value), value, _imageQuality, (next) {
                setState(() => _imageQuality = next);
                _saveOption('webclient-default-image-quality', next);
              }),
          ],
        ),
        _panel(
          'Default codec',
          [
            const RadioListTile<String>(
              value: 'vp9',
              groupValue: 'vp9',
              onChanged: null,
              title: Text('VP9'),
              subtitle: Text('Web Client V1 decoder'),
            ),
          ],
        ),
        _panel(
          'Other default options',
          [
            _switch('Show remote cursor', _showRemoteCursor, (value) {
              setState(() => _showRemoteCursor = value);
              _saveOption('webclient-show-remote-cursor', value);
            }),
            _switch('Enable audio', _enableAudio, (value) {
              setState(() => _enableAudio = value);
              _saveOption('webclient-enable-audio', value);
            }),
            _switch('Enable clipboard', _enableClipboard, (value) {
              setState(() => _enableClipboard = value);
              _saveOption('webclient-enable-clipboard', value);
            }),
          ],
        ),
      ],
    );
  }

  Widget _account() {
    final username = getUsername();
    return _panel(
      'Account',
      [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(username ?? translate('Not signed in')),
          subtitle: Text(
            username == null
                ? translate('Sign in to sync address books and registered devices.')
                : translate('Address books and devices are synchronized.'),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              if (username == null) {
                showLogin();
              } else {
                logout();
              }
              setState(() {});
            },
            icon: Icon(username == null ? Icons.login : Icons.logout, size: 18),
            label: Text(translate(username == null ? 'Login' : 'Logout')),
          ),
        ),
      ],
    );
  }

  Widget _about() {
    final clientVersion = FFI.getByName('version');
    return _panel(
      'About',
      [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.desktop_windows_outlined),
          title: Text('RustDesk Web Client V1'),
          subtitle: Text('AGPL-3.0 · complete corresponding source'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: Text(translate('Version')),
          subtitle: Text(clientVersion.isEmpty ? '1.1.9' : clientVersion),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.code_rounded),
          title: Text(translate('Corresponding source')),
          subtitle: const Text('47a7b7313bb906ebdae36bd16838bdefa8853639'),
          trailing: const Icon(Icons.open_in_new_rounded, size: 18),
          onTap: () => launchUrl(Uri.parse(_sourceUrl)),
        ),
      ],
    );
  }

  Widget _panel(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebClientTheme.surface,
        border: Border.all(color: WebClientTheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translate(title),
            style: TextStyle(
              color: WebClientTheme.text,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _serverField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(labelText: translate(label)),
      ),
    );
  }

  Widget _radio(
    String label,
    String value,
    String group,
    ValueChanged<String> onChanged,
  ) {
    return RadioListTile<String>(
      value: value,
      groupValue: group,
      title: Text(translate(label)),
      onChanged: (next) => onChanged(next!),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      title: Text(translate(label)),
      onChanged: onChanged,
    );
  }

  String _sectionLabel(_SettingsSection section) {
    switch (section) {
      case _SettingsSection.network:
        return 'Network';
      case _SettingsSection.display:
        return 'Display';
      case _SettingsSection.account:
        return 'Account';
      case _SettingsSection.about:
        return 'About';
      default:
        return 'General';
    }
  }

  IconData _sectionIcon(_SettingsSection section) {
    switch (section) {
      case _SettingsSection.network:
        return Icons.link_rounded;
      case _SettingsSection.display:
        return Icons.monitor_outlined;
      case _SettingsSection.account:
        return Icons.person_outline_rounded;
      case _SettingsSection.about:
        return Icons.info_outline_rounded;
      default:
        return Icons.settings_outlined;
    }
  }

  String _themeLabel(String value) {
    if (value == 'light') return 'Light';
    if (value == 'dark') return 'Dark';
    return 'Follow system';
  }

  String _qualityLabel(String value) {
    if (value == 'best') return 'Best quality';
    if (value == 'low') return 'Optimize reaction time';
    return 'Balanced';
  }
}
