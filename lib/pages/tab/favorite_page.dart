import 'package:FEhViewer/common/global.dart';
import 'package:FEhViewer/generated/l10n.dart';
import 'package:FEhViewer/models/entity/favorite.dart';
import 'package:FEhViewer/models/index.dart';
import 'package:FEhViewer/models/states/gallery_model.dart';
import 'package:FEhViewer/models/states/user_model.dart';
import 'package:FEhViewer/pages/tab/tab_base.dart';
import 'package:FEhViewer/route/navigator_util.dart';
import 'package:FEhViewer/route/routes.dart';
import 'package:FEhViewer/utils/toast.dart';
import 'package:FEhViewer/utils/utility.dart';
import 'package:FEhViewer/widget/eh_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../item/gallery_item.dart';

class FavoriteTab extends StatefulWidget {
  const FavoriteTab({Key key, this.tabIndex, this.scrollController})
      : super(key: key);
  final tabIndex;
  final scrollController;

  @override
  State<StatefulWidget> createState() {
    return _FavoriteTabState();
  }
}

class _FavoriteTabState extends State<FavoriteTab> {
  String _title = '';
  final List<GalleryItem> _gallerItemBeans = [];
  String _curFavcat = '';
  bool _loading = false;
  int _curPage = 0;
  int _maxPage = 0;
  bool _isLoadMore = false;

  //页码跳转的控制器
  final TextEditingController _pageController = TextEditingController();

  void _setTitle(String title) {
    setState(() {
      _title = title;
    });
  }

  @override
  void initState() {
    super.initState();
    _curFavcat = 'a';
    _loadDataFirst();
  }

  SliverList gallerySliverListView(List<GalleryItem> gallerItemBeans) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          if (index == gallerItemBeans.length - 1 && _curPage < _maxPage - 1) {
            Global.logger.v('load more');
            _loadDataMore();
          }
//          Global.logger.v('build ${gallerItemBeans[index].gid} ');
          return ChangeNotifierProvider<GalleryModel>.value(
            value: GalleryModel()
              ..initData(gallerItemBeans[index], tabIndex: widget.tabIndex),
            child: GalleryItemWidget(
              galleryItem: gallerItemBeans[index],
              tabIndex: widget.tabIndex,
            ),
          );
        },
        childCount: gallerItemBeans.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S ln = S.of(context);
    if (_title.isEmpty) {
      _title = ln.all_Favorites;
    }

//    final size = MediaQuery.of(context).size;
//     final width = size.width;
//    final height = size.height;

    return CupertinoPageScaffold(
      child: Selector<UserModel, bool>(
          selector: (BuildContext context, UserModel provider) =>
              provider.isLogin,
          builder: (BuildContext context, bool isLogin, Widget child) {
            return isLogin
                ? CustomScrollView(
                    controller: widget.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: <Widget>[
                      CupertinoSliverNavigationBar(
                        heroTag: 'fav',
                        largeTitle: TabPageTitle(
                          title: _title,
                        ),
                        trailing: Container(
                          width: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CupertinoButton(
                                padding: const EdgeInsets.all(0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.fromLTRB(4, 2, 4, 2),
                                    color: CupertinoColors.activeBlue,
                                    child: Text(
                                      '${_curPage + 1}',
                                      style: const TextStyle(
                                          color: CupertinoColors.white),
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  _jumtToPage(context);
                                },
                              ),
                              _buildFavcatButton(context),
                            ],
                          ),
                        ),
                      ),
                      CupertinoSliverRefreshControl(
                        onRefresh: () async {
                          await _reloadData();
                        },
                      ),
                      SliverSafeArea(
                        top: false,
                        sliver: _loading
                            ? SliverFillRemaining(
                                child: Container(
                                  padding: const EdgeInsets.only(bottom: 50),
                                  child: const CupertinoActivityIndicator(
                                    radius: 14.0,
                                  ),
                                ),
                              )
                            : getGalleryList(_gallerItemBeans, widget.tabIndex,
                                maxPage: _maxPage,
                                curPage: _curPage,
                                loadMord: _loadDataMore),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 150),
                          child: _isLoadMore
                              ? const CupertinoActivityIndicator(
                                  radius: 14,
                                )
                              : Container(),
                        ),
                      ),
                    ],
                  )
                : CustomScrollView(slivers: <Widget>[
                    CupertinoSliverNavigationBar(
                      largeTitle: TabPageTitle(
                        title: ln.not_login,
                        isLoading: false,
                      ),
                      transitionBetweenRoutes: false,
                    ),
                  ]);
          }),
    );
  }

  _loadDataFirst() async {
    setState(() {
      _loading = true;
    });
    final Tuple2<List<GalleryItem>, int> tuple =
        await Api.getFavorite(favcat: _curFavcat);
    final List<GalleryItem> gallerItemBeans = tuple.item1;

    setState(() {
      _gallerItemBeans.clear();
      _gallerItemBeans.addAll(gallerItemBeans);
      _curPage = 0;
      _maxPage = tuple.item2;
      _loading = false;
    });
  }

  _reloadData() async {
    if (_loading) {
      setState(() {
        _loading = false;
      });
    }
    final Tuple2<List<GalleryItem>, int> tuple =
        await Api.getFavorite(favcat: _curFavcat);
    final List<GalleryItem> gallerItemBeans = tuple.item1;
    setState(() {
      _curPage = 0;
      _gallerItemBeans.clear();
      _gallerItemBeans.addAll(gallerItemBeans);
      _maxPage = tuple.item2;
    });
  }

  _loadDataMore() async {
    if (_isLoadMore) {
      return;
    }

    // 增加延时 避免build期间进行 setState
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _isLoadMore = true;
    });

    _curPage += 1;
    final Tuple2<List<GalleryItem>, int> tuple =
        await Api.getFavorite(favcat: _curFavcat, page: _curPage);
    final List<GalleryItem> gallerItemBeans = tuple.item1;

    setState(() {
      _gallerItemBeans.addAll(gallerItemBeans);
      _isLoadMore = false;
    });
  }

  _loadFromPage(int page) async {
    Global.logger.v('jump to page  =>  $page');
    setState(() {
      _loading = true;
    });
    _curPage = page;
    final Tuple2<List<GalleryItem>, int> tuple =
        await Api.getFavorite(favcat: _curFavcat, page: _curPage);
    final List<GalleryItem> gallerItemBeans = tuple.item1;
    setState(() {
      _gallerItemBeans.clear();
      _gallerItemBeans.addAll(gallerItemBeans);
      _maxPage = tuple.item2;
      _loading = false;
    });
  }

  /// 跳转页码
  Future<void> _jumtToPage(BuildContext context) async {
    _jump(BuildContext context) {
      final String _input = _pageController.text.trim();

      if (_input.isEmpty) {
        showToast('输入为空');
      }

      // 数字检查
      if (!RegExp(r'(^\d+$)').hasMatch(_input)) {
        showToast('输入格式有误');
      }

      final int _toPage = int.parse(_input) - 1;
      if (_toPage >= 0 && _toPage <= _maxPage) {
        FocusScope.of(context).requestFocus(FocusNode());
        _loadFromPage(_toPage);
        Navigator.of(context).pop();
      } else {
        showToast('输入范围有误');
      }
    }

    return showCupertinoDialog<void>(
      context: context,
      // barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('页面跳转'),
          content: Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('跳转范围 1~$_maxPage'),
                ),
                CupertinoTextField(
                  controller: _pageController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  onEditingComplete: () {
                    // 点击键盘完成
                    // 画廊跳转
                    _jump(context);
                  },
                )
              ],
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () {
                // 画廊跳转
                _jump(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFavcatButton(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(0),
      onPressed: () {
        debugPrint('sel icon tapped');
        // 跳转收藏夹选择页
        NavigatorUtil.jump(context, EHRoutes.selFavorie).then((result) async {
          if (result.runtimeType == FavcatItemBean) {
            FavcatItemBean fav = result;
            Global.loggerNoStack.i('${fav.title}');
            if (_curFavcat != fav.key) {
              Global.loggerNoStack.v('修改favcat to ${fav.title}');
              _setTitle(fav.title);
              _curFavcat = fav.key;
              setState(() {
                _loading = true;
                _gallerItemBeans.clear();
              });
              await _loadDataFirst();
            } else {
              Global.loggerNoStack.v('未修改favcat');
            }
          }
        });
      },
      child: const Icon(
        FontAwesomeIcons.star,
      ),
    );
  }
}