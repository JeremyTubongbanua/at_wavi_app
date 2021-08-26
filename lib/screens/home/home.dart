import 'dart:async';

import 'package:at_wavi_app/common_components/custom_input_field.dart';
import 'package:at_wavi_app/common_components/empty_widget.dart';
import 'package:at_wavi_app/common_components/header.dart';
import 'package:at_wavi_app/common_components/loading_widget.dart';
import 'package:at_wavi_app/model/user.dart';
import 'package:at_wavi_app/routes/route_names.dart';
import 'package:at_wavi_app/routes/routes.dart';
import 'package:at_wavi_app/screens/home/widgets/Home_details.dart';
import 'package:at_wavi_app/screens/home/widgets/home_channel.dart';
import 'package:at_wavi_app/screens/home/widgets/home_empty_details.dart';
import 'package:at_wavi_app/screens/home/widgets/home_featured.dart';
import 'package:at_wavi_app/screens/home/widgets/home_private_account.dart';
import 'package:at_wavi_app/screens/options.dart';
import 'package:at_wavi_app/screens/website_webview/website_webview.dart';
import 'package:at_wavi_app/services/at_key_get_service.dart';
import 'package:at_wavi_app/services/at_key_set_service.dart';
import 'package:at_wavi_app/services/backend_service.dart';
import 'package:at_wavi_app/services/common_functions.dart';
import 'package:at_wavi_app/services/field_order_service.dart';
import 'package:at_wavi_app/view_models/follow_service.dart';
import 'package:at_wavi_app/services/nav_service.dart';
import 'package:at_wavi_app/services/search_service.dart';
import 'package:at_wavi_app/services/size_config.dart';
import 'package:at_wavi_app/services/twitter_service.dart';
import 'package:at_wavi_app/utils/at_enum.dart';
import 'package:at_wavi_app/utils/colors.dart';
import 'package:at_wavi_app/utils/constants.dart';
import 'package:at_wavi_app/utils/images.dart';
import 'package:at_wavi_app/utils/text_styles.dart';
import 'package:at_wavi_app/utils/theme.dart';
import 'package:at_wavi_app/view_models/theme_view_model.dart';
import 'package:at_wavi_app/view_models/user_preview.dart';
import 'package:at_wavi_app/view_models/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:at_location_flutter/utils/constants/constants.dart'
    as location_package_constants;

enum HOME_TABS { DETAILS, CHANNELS, FEATURED }

class HomeScreen extends StatefulWidget {
  final ThemeData? themeData;
  final bool isPreview;
  HomeScreen({this.themeData, this.isPreview = false});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  HOME_TABS _currentTab = HOME_TABS.DETAILS;
  bool _isDark = false;
  ThemeData? _themeData;
  late String _name;
  late User _currentUser;

  bool _isSearchScreen = false;

  bool hideHeader = false, loadingSearchedAtsign = false;
  String searchedAtsign = '';
  late AnimationController _inputBoxController;

  @override
  void initState() {
    _inputBoxController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));

    if (widget.isPreview) {
      _currentUser = Provider.of<UserPreview>(context, listen: false).user()!;
    } else {
      _currentUser = Provider.of<UserProvider>(context, listen: false).user!;
    }

    if ((widget.isPreview) &&
        (_currentUser.atsign !=
            BackendService().atClientInstance.currentAtSign)) {
      _isSearchScreen = true;
    }

    initPackages();

    _getThemeData();
    // WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
    //   await Provider.of<FollowService>(NavService.navKey.currentContext!,
    // listen: false)().getFollowers();
    //   await Provider.of<FollowService>(NavService.navKey.currentContext!,
    // listen: false)().getFollowing();
    // });
    super.initState();
  }

  getCurrentUserName() {
    if (widget.isPreview) {
      _currentUser = Provider.of<UserPreview>(context, listen: false).user()!;
    } else {
      _currentUser = Provider.of<UserProvider>(context, listen: false).user!;
    }

    _name = _currentUser.firstname.value ?? '';
    if (_currentUser.lastname.value != null) {
      _name = '$_name ${_currentUser.lastname.value}';
    }

    if (_name.isEmpty) {
      _name = _currentUser.atsign.replaceFirst('@', '');
    }
  }

  initPackages() async {
    location_package_constants.MixedConstants.setMapKey(MixedConstants.MAP_KEY);
    location_package_constants.MixedConstants.setApiKey(MixedConstants.API_KEY);
  }

  _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  _getThemeData() async {
    if (widget.themeData != null) {
      _themeData = widget.themeData!;
    } else {
      _themeData =
          await Provider.of<ThemeProvider>(context, listen: false).getTheme();
    }

    if (_themeData!.scaffoldBackgroundColor ==
        Themes.darkTheme().scaffoldBackgroundColor) {
      _isDark = true;
    }

    if (mounted) {
      setState(() {});
    }
  }

  _animate() {
    if (_inputBoxController.isCompleted) {
      setState(() {
        hideHeader = false;
        searchedAtsign = '';
      });
      _inputBoxController.reverse();
      return;
    }

    setState(() {
      hideHeader = true;
    });
    _inputBoxController.forward();
  }

  @override
  Widget build(BuildContext context) {
    getCurrentUserName();

    SizeConfig().init(context);
    if (_themeData == null) {
      return CircularProgressIndicator();
    } else {
      return Scaffold(
        backgroundColor: _themeData!.scaffoldBackgroundColor,
        bottomNavigationBar: widget.isPreview
            ? null
            : BottomNavigationBar(
                backgroundColor: _themeData!.scaffoldBackgroundColor,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.notifications),
                    label: '',
                  )
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: ColorConstants.orange,
                onTap: _onItemTapped,
                // elevation: 0,
              ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: RefreshIndicator(
              onRefresh: () async {
                if (_isSearchScreen) {
                  await SearchService().getAtsignDetails(_currentUser.atsign);
                } else {
                  await BackendService().sync();
                }
                setState(() {});
              },
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    header(),
                    hideHeader && loadingSearchedAtsign
                        ? LinearProgressIndicator()
                        : SizedBox(),
                    SizedBox(height: 30.toHeight),
                    // content
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 116.toWidth,
                          height: 116.toWidth,
                          decoration: BoxDecoration(
                            color: ColorConstants.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: (_currentUser.image.value != null)
                              ? CircleAvatar(
                                  radius: 50.toFont,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage:
                                      Image.memory(_currentUser.image.value)
                                          .image,
                                )
                              : Icon(
                                  Icons.person,
                                  size: 50,
                                ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(_name,
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: _themeData!.primaryColor,
                                      fontWeight: FontWeight.w600)),
                              SizedBox(height: 8.toHeight),
                              Text(
                                _currentUser.atsign,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ColorConstants.orange,
                                  fontSize: 18.toFont,
                                ),
                              ),
                              SizedBox(height: 18.5.toHeight),
                              Divider(
                                color: _themeData!.highlightColor,
                              ),
                              SizedBox(height: 18.5.toHeight),
                              followersFollowingRow(),
                            ],
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 20.toHeight),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: SizedBox(
                            height: 55.toHeight,
                            child: TextButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(_themeData!
                                        .highlightColor
                                        .withOpacity(0.1)),
                              ),
                              onPressed: widget.isPreview
                                  ? () async {
                                      if (_isSearchScreen) {
                                        LoadingDialog().show(text: 'Updating');
                                        await Provider.of<FollowService>(
                                                NavService
                                                    .navKey.currentContext!,
                                                listen: false)
                                            .performFollowUnfollow(
                                                _currentUser.atsign);
                                        LoadingDialog().hide();
                                        setState(() {});
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          backgroundColor: ColorConstants.RED,
                                          content: Text(
                                            'This is a Preview',
                                            style: CustomTextStyles
                                                .customTextStyle(
                                              ColorConstants.white,
                                            ),
                                          ),
                                        ));
                                      }
                                    }
                                  : () async {
                                      SetupRoutes.push(
                                          NavService.navKey.currentContext!,
                                          Routes.EDIT_PERSONA);
                                    },
                              child: Text(
                                _isSearchScreen
                                    ? (Provider.of<FollowService>(
                                                NavService
                                                    .navKey.currentContext!,
                                                listen: false)
                                            .isFollowing(_currentUser.atsign)
                                        ? 'Following'
                                        : 'Follow')
                                    : 'Edit Profile',
                                style: TextStyle(
                                    fontSize: 16.toFont,
                                    color: _themeData!.primaryColor
                                        .withOpacity(0.5)),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 55.toHeight,
                            child: TextButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(_themeData!
                                        .highlightColor
                                        .withOpacity(0.1)),
                              ),
                              onPressed: widget.isPreview
                                  ? () {
                                      if (_isSearchScreen) {
                                        shareProfile();
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          backgroundColor: ColorConstants.RED,
                                          content: Text(
                                            'This is a Preview',
                                            style: CustomTextStyles
                                                .customTextStyle(
                                              ColorConstants.white,
                                            ),
                                          ),
                                        ));
                                      }
                                    }
                                  : () {
                                      shareProfile();
                                    },
                              child: Text('Share Profile',
                                  style: TextStyle(
                                      fontSize: 16.toFont,
                                      color: _themeData!.primaryColor
                                          .withOpacity(0.5))),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 25.toHeight),

                    _isSearchScreen && SearchService().isPrivateAccount
                        ? HomePrivateAccount(_themeData!)
                        : SizedBox(),

                    _isSearchScreen && SearchService().isPrivateAccount
                        ? SizedBox()
                        : Container(
                            height: 70.toHeight,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: _themeData!.primaryColor
                                      .withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _currentTab = HOME_TABS.DETAILS;
                                      });
                                    },
                                    child: tab('Details', HOME_TABS.DETAILS),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _currentTab = HOME_TABS.CHANNELS;
                                        });
                                      },
                                      child:
                                          tab('Channels', HOME_TABS.CHANNELS)),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _currentTab = HOME_TABS.FEATURED;
                                      });
                                    },
                                    child: tab('Featured', HOME_TABS.FEATURED),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    SizedBox(
                      height:
                          _isSearchScreen && SearchService().isPrivateAccount
                              ? 0
                              : 20.toHeight,
                    ),
                    _isSearchScreen && SearchService().isPrivateAccount
                        ? SizedBox()
                        : homeContent()
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget header() {
    return Stack(
      children: [
        hideHeader
            ? SizedBox()
            : Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Header(
                  leading: Row(
                    children: [
                      widget.isPreview
                          ? InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Icon(
                                Icons.arrow_back,
                                color: _themeData!.primaryColor,
                              ),
                            )
                          : SizedBox(),
                      SizedBox(width: 5),
                      Text(
                        widget.isPreview ? 'Preview' : 'My Profile',
                        style: TextStyle(
                            fontSize: 18.toFont,
                            color: _themeData!.primaryColor,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  trailing: widget.isPreview
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  onTap: () {
                                    _animate();
                                    // SetupRoutes.push(
                                    //     context, Routes.SEARCH_SCREEN);
                                  },
                                  child: Icon(Icons.search,
                                      color: _themeData!.primaryColor),
                                ),
                              ),
                              SizedBox(height: 18.5.toHeight),
                              Divider(
                                color: _themeData!.highlightColor,
                              ),
                              SizedBox(height: 18.5.toHeight),
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: StadiumBorder(),
                                      builder: (BuildContext context) {
                                        return Container(
                                          height: 350,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 20, horizontal: 20),
                                          decoration: BoxDecoration(
                                            color: _themeData!
                                                .scaffoldBackgroundColor,
                                            borderRadius: BorderRadius.only(
                                              topLeft:
                                                  const Radius.circular(12.0),
                                              topRight:
                                                  const Radius.circular(12.0),
                                            ),
                                          ),
                                          child: Options(name: _name),
                                        );
                                      });
                                },
                                child: Icon(Icons.more_vert,
                                    color: _themeData!.primaryColor),
                              )
                            ],
                          ),
                        ),
                ),
              ),
        _isSearchScreen
            ? SizedBox()
            : Positioned(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.1, 0),
                    end: Offset.zero,
                  ).animate(_inputBoxController),
                  child: CustomInputField(
                    padding: EdgeInsets.only(right: 10),
                    width: 343.toWidth,
                    // height: 60.toHeight,
                    bgColor: ColorConstants.MILD_GREY,
                    hintText: '',
                    height: 50,
                    expands: false,
                    maxLines: 1,
                    icon: loadingSearchedAtsign
                        ? Icons.access_time
                        : Icons.search,
                    secondIcon: Icons.cancel,
                    borderColor: Colors.transparent,
                    focusedBorderColor: Colors.transparent,
                    textColor: ColorConstants.black,
                    initialValue: searchedAtsign,
                    baseOffset: searchedAtsign.length,
                    value: (String s) {
                      setState(() {
                        searchedAtsign = s;
                      });
                    },
                    onSubmitted: (_str) {
                      _searchProfile();
                    },
                    onIconTap: () {
                      _searchProfile();
                    },
                    onSecondIconTap: _animate,
                  ),
                ),
              )
      ],
    );
  }

  Widget followersFollowingRow() {
    return Consumer<FollowService>(builder: (context, _provider, _) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSearchScreen
                      ? (SearchService().following_count ?? '-').toString()
                      : '${followsCount(_provider.following.list!.length)}',
                  style: TextStyle(
                      fontSize: 18.toFont,
                      color: _isDark
                          ? _themeData!.primaryColor
                          : _themeData!.highlightColor,
                      fontWeight: FontWeight.w800),
                ),
                GestureDetector(
                  onTap: () {
                    SetupRoutes.push(
                      context,
                      Routes.FOLLOWING_SCREEN,
                      arguments: {
                        'forSearchedAtsign': _isSearchScreen,
                      },
                    );
                  },
                  child: Text(
                    'Following',
                    style: TextStyle(
                        fontSize: 14.toFont,
                        color: _themeData!.primaryColor.withOpacity(0.5)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSearchScreen
                      ? (SearchService().followers_count ?? '-').toString()
                      : '${followsCount(_provider.followers.list!.length)}',
                  style: TextStyle(
                      fontSize: 18.toFont,
                      color: _isDark
                          ? _themeData!.primaryColor
                          : _themeData!.highlightColor,
                      fontWeight: FontWeight.w800),
                ),
                GestureDetector(
                  onTap: () {
                    SetupRoutes.push(
                      context,
                      Routes.FOLLOWING_SCREEN,
                      arguments: {
                        'forSearchedAtsign': _isSearchScreen,
                        'tabIndex': 1,
                      },
                    );
                  },
                  child: Text(
                    'Followers',
                    style: TextStyle(
                        fontSize: 14.toFont,
                        color: _themeData!.primaryColor.withOpacity(0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget tab(String title, HOME_TABS tab) {
    return Container(
      decoration: BoxDecoration(
        color: _currentTab == tab
            ? _themeData!.highlightColor
            : _themeData!.scaffoldBackgroundColor,
        border: _currentTab == tab
            ? Border.all(
                color: _isDark
                    ? _themeData!.highlightColor
                    : ColorConstants.lightGrey)
            : null,
        // borderRadius: _currentTab == tab ? BorderRadius.circular(60) : null,
        borderRadius: BorderRadius.circular(60),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
              color: _currentTab == tab
                  ? Colors.white
                  : _themeData!.highlightColor,
              fontSize: 18.toFont),
        ),
      ),
    );
  }

  Widget homeContent() {
    if (_currentTab == HOME_TABS.DETAILS) {
      return CommonFunctions().isFieldsPresentForCategory(AtCategory.DETAILS,
                  isPreview: widget.isPreview) ||
              CommonFunctions().isFieldsPresentForCategory(
                  AtCategory.ADDITIONAL_DETAILS,
                  isPreview: widget.isPreview) ||
              CommonFunctions().isFieldsPresentForCategory(AtCategory.LOCATION,
                  isPreview: widget.isPreview)
          ? HomeDetails(themeData: _themeData, isPreview: widget.isPreview)
          : getEmptyWidget(_themeData!);
    } else if (_currentTab == HOME_TABS.CHANNELS) {
      return CommonFunctions().isFieldsPresentForCategory(AtCategory.GAMER,
                  isPreview: widget.isPreview) ||
              CommonFunctions().isFieldsPresentForCategory(AtCategory.SOCIAL,
                  isPreview: widget.isPreview)
          ? HomeChannels(themeData: _themeData, isPreview: widget.isPreview)
          : getEmptyWidget(_themeData!);
    } else if (_currentTab == HOME_TABS.FEATURED) {
      return CommonFunctions().isTwitterFeatured(isPreview: widget.isPreview) ||
              CommonFunctions().isInstagramFeatured(isPreview: widget.isPreview)
          ? HomeFeatured(
              twitterUsername: _currentUser.twitter.value,
              instagramUsername: _currentUser.instagram.value,
              themeData: _themeData)
          : getEmptyWidget(_themeData!);
    } else
      return SizedBox();
  }

  _searchProfile() async {
    bool _isSearchingSameAtsign = SearchService().user.atsign == searchedAtsign;

    if (loadingSearchedAtsign) {
      return;
    }
    setState(() {
      loadingSearchedAtsign = true;
    });

    bool _isPresent = _isSearchingSameAtsign;
    if (!_isSearchingSameAtsign) {
      _isPresent = await CommonFunctions().checkAtsign(searchedAtsign);
    }

    if (_isPresent) {
      User? _res = SearchService().user;

      if (!_isSearchingSameAtsign) {
        _res = await SearchService().getAtsignDetails(searchedAtsign);
      }

      if (_res == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: ColorConstants.RED,
          content: Text(
            'Something went wrong',
            style: CustomTextStyles.customTextStyle(
              ColorConstants.white,
            ),
          ),
        ));
        setState(() {
          loadingSearchedAtsign = false;
        });
        return;
      }

      setState(() {
        loadingSearchedAtsign = false;
      });
      // Provider.of<UserPreview>(context,
      //         listen: false)
      //     .setSearchedUser(_res);
      Provider.of<UserPreview>(context, listen: false).setUser = _res;
      FieldOrderService().setPreviewOrder = SearchService().fieldOrders;

      await SetupRoutes.push(context, Routes.HOME, arguments: {
        'themeData': SearchService().currentAtsignThemeData,
        'isPreview': true,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: ColorConstants.RED,
        content: Text(
          '$searchedAtsign not found',
          style: CustomTextStyles.customTextStyle(
            ColorConstants.white,
          ),
        ),
      ));
      setState(() {
        loadingSearchedAtsign = false;
      });
    }
  }

  Widget getEmptyWidget(ThemeData themeData) {
    return _isSearchScreen ? EmptyWidget(themeData) : HomeEmptyDetails();
  }

  shareProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebsiteScreen(
          title: 'Wavi.ng',
          url: 'https://wavi.ng/${_currentUser.atsign}',
          isShareProfileScreen: true,
        ),
      ),
    );
  }

  String followsCount(num) {
    if (num > 999 && num < 99999) {
      return "${(num / 1000).toStringAsFixed(1)} K";
    } else if (num > 99999 && num < 999999) {
      return "${(num / 1000).toStringAsFixed(0)} K";
    } else if (num > 999999 && num < 999999999) {
      return "${(num / 1000000).toStringAsFixed(1)} M";
    } else if (num > 999999999) {
      return "${(num / 1000000000).toStringAsFixed(1)} B";
    } else {
      return num.toString();
    }
  }
}
