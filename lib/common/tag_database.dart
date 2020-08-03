import 'dart:convert';

import 'package:FEhViewer/common/global.dart';
import 'package:FEhViewer/models/entity/tag_translat.dart';
import 'package:FEhViewer/utils/db_util.dart';
import 'package:FEhViewer/utils/dio_util.dart';
import 'package:FEhViewer/utils/storage.dart';
import 'package:FEhViewer/values/const.dart';
import 'package:FEhViewer/values/storages.dart';
import 'package:dio/dio.dart';

const int connectTimeout = 10000;
const int receiveTimeout = 30000;

class EhTagDatabase {
  ///tag翻译
  static Future<String> generateTagTranslat() async {
    final HttpManager httpManager =
        HttpManager.getInstance('https://api.github.com');

    const String url = '/repos/EhTagTranslation/Database/releases/latest';

    final String urlJsonString = await httpManager.get(url);
    final Map<String, dynamic> urlJson =
        jsonDecode(urlJsonString) as Map<String, dynamic>;

    // 获取发布时间 作为远程版本号
    final String remoteVer =
        (urlJson != null ? urlJson['published_at']?.trim() : '') as String;
    Global.loggerNoStack.v('remoteVer $remoteVer');

    // 获取当前本地版本
    final String localVer =
        StorageUtil().getString(TAG_TRANSLAT_VER)?.trim() ?? '';
    Global.loggerNoStack.v('localVer $localVer');

    if (remoteVer != localVer) {
      Global.loggerNoStack.v('TagTranslat更新');
      final List assList = urlJson['assets'];

      final Map<String, String> assMap = <String, String>{};
      assList.forEach((assets) {
        assMap[assets['name']] = assets['browser_download_url'];
      });
      final String dbUrl = assMap['db.text.json'];

      Global.loggerNoStack.v(dbUrl);

      final HttpManager httpDB = HttpManager.getInstance();

      final Options options = Options(receiveTimeout: receiveTimeout);

      final String dbJson = await httpDB.get(dbUrl, options: options);
      if (dbJson != null) {
        final Map dataAll = jsonDecode(dbJson.toString()) as Map;
        final List listDataP = dataAll['data'] as List;

        await tagSaveToDB(listDataP);
        StorageUtil().setString(TAG_TRANSLAT_VER, remoteVer);
      }
      Global.loggerNoStack.v('tag翻译更新完成');
    }

    return remoteVer;
  }

  /// 保存到数据库
  static Future<void> tagSaveToDB(List listDataP) async {
    final List<TagTranslat> tags = <TagTranslat>[];

    listDataP.forEach((objC) {
      Global.loggerNoStack.v('${objC['namespace']}  ${objC['count']}');
      final String _namespace = objC['namespace'] as String;
      Map mapC = objC['data'] as Map;
      mapC.forEach((key, value) {
        final String _key = key as String;
        final String _name = (value['name'] ?? '') as String;
        final String _intro = (value['intro'] ?? '') as String;
        final String _links = (value['links'] ?? '') as String;

        tags.add(
            TagTranslat(_namespace, _key, _name, intro: _intro, links: _links));
      });
    });

    await DataBaseUtil().insertTagAll(tags);

    Global.loggerNoStack.v('tag中文翻译数量 ${tags.length}');
  }

  static Future<String> getTranTag(String tag, {String nameSpase}) async {
    if (tag.contains(':')) {
      final RegExp rpfx = RegExp(r'(\w:)(.+)');
      final RegExpMatch rult = rpfx.firstMatch(tag);
      final String pfx = rult.group(1) ?? '';
      final String _nameSpase = EHConst.prefixToNameSpaceMap[pfx] as String;
      final String _tag = rult.group(2) ?? '';
      final String _transTag =
          await DataBaseUtil().getTagTransStr(_tag, namespace: _nameSpase);

      return _transTag != null ? '$pfx$_transTag' : tag;
    } else {
      return await DataBaseUtil().getTagTransStr(tag, namespace: nameSpase);
    }
  }
}