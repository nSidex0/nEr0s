import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

import '../../fehviewer.dart';

EhMytags parseMyTags(String html) {
  final Document document = parse(html);

  final tagsets = <EhMytagSet>[];

  late String selectedValue = '';

  // 解析tagsets
  final Element? tagsetElm =
      document.querySelector('#tagset_outer > div:nth-child(3) > select');

  if (tagsetElm != null) {
    final tagsetElms = tagsetElm.children;
    logger.d('tagsetElms.length ${tagsetElms.length}');
    for (final _tagset in tagsetElms) {
      final value = _tagset.attributes['value'];
      if (value == null) {
        continue;
      }
      final isSelected = _tagset.attributes['selected'] == 'selected';

      // logger.d('text:${_tagset.text}');

      final name = _tagset.text.replaceAllMapped(
          RegExp(r'(.+)\((\d+)\)'), (match) => match.group(1) ?? '');
      final count = _tagset.text.replaceAllMapped(
          RegExp(r'(.+)\((\d+)\)'), (match) => match.group(2) ?? '');
      if (isSelected) {
        selectedValue = value;
      }

      // if (_tagset.text.trim().endsWith('(Default)')) {
      //   // defaultProfile = value;
      // }

      logger.d('name:$name  count:$count');

      tagsets.add(EhMytagSet(
        name: name,
        tagCount: count,
        value: value,
      ));
    }
  }

  final usertags = <EhUsertag>[];
  final Element? userTagsElm = document.querySelector('#usertags_outer');
  if (userTagsElm != null) {
    final userTagElms = userTagsElm.children;
    for (final _usertagElm in userTagElms) {
      final id = _usertagElm.attributes['id'];
      if (id == 'usertag_0') {
        continue;
      }
      final _title = _usertagElm.children.first.children.first.children.first
              .attributes['title'] ??
          '';
      final watch = (_usertagElm.children[1].children.first.children.first
                  .attributes['checked'] ??
              false) ==
          'checked';
      final hide = (_usertagElm.children[2].children.first.children.first
                  .attributes['checked'] ??
              false) ==
          'checked';

      // final color =
      //     (_usertagElm.children[4].children.first.attributes['value'] ?? '')
      //         .replaceAll('#', '');

      final style = _usertagElm.children.first.children.first.children.first
              .attributes['style'] ??
          '';

      late String textColor;
      late String color;
      late String borderColor;

      final RegExp colorRex = RegExp(r'#(\w{6})');
      if (style != null) {
        final Iterable<RegExpMatch> matches = colorRex.allMatches(style);
        textColor = matches.elementAt(0)[0] ?? '';
        borderColor = matches.elementAt(3)[1] ?? '';
        color = matches.elementAt(3)[0] ?? '';
      }

      final tagweight =
          _usertagElm.children[5].children.first.attributes['value'] ?? '';

      usertags.add(EhUsertag(
        title: _title,
        watch: watch,
        hide: hide,
        colorCode: color,
        borderColor: borderColor,
        textColor: textColor,
      ));
    }
  }

  return EhMytags(
    tagsets: tagsets,
    usertags: usertags,
    canDelete: html.contains('do_tagset_delete()'),
  );
}