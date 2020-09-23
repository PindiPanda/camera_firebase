import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'constants.dart';
import 'package:camera_firebase/TakePictureScreen.dart';
import 'package:camera_firebase/LoadingIndicator.dart';
import 'package:camera_firebase/CircleButton.dart';

final _firestore = FirebaseFirestore.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            "JP's Camera App",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24.0,
            ),
          ),
          elevation: 0.0,
          backgroundColor: Colors.deepOrange,
        ),
        body: MySlidingPanel(),
      ),
    ),
  );
}

class MySlidingPanel extends StatefulWidget {
  MySlidingPanelState createState() => MySlidingPanelState();
}

class MySlidingPanelState extends State<MySlidingPanel> {
  TextEditingController controller = TextEditingController();
  String comment;
  bool isTyping = false;
  PanelController pc = new PanelController();
  TakePictureScreen cameraScreen;

  StorageReference storageReference;
  StorageUploadTask task;

  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      controller: pc,
      defaultPanelState: PanelState.OPEN,
      backdropEnabled: true,
      backdropColor: Colors.deepOrange,
      backdropOpacity: 1,
      backdropTapClosesPanel: false,
      minHeight: 100.0,
      maxHeight: isTyping ? 100.0 : 700.0,
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(25),
        topLeft: Radius.circular(25),
        bottomRight: Radius.circular(0),
        bottomLeft: Radius.circular(0),
      ),
      onPanelClosed: () async {
        setState(() {
          if (cameraScreen == null) {
            cameraScreen = TakePictureScreen();
          }
        });
      },
      onPanelOpened: () {
        setState(() {});
      },
      body: cameraScreen != null
          ? Align(
              alignment: Alignment.topCenter,
              child: cameraScreen,
            )
          : LoadingIndicator(),
      collapsed: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CircleButton(
              iconData: Icons.sync,
              onPressed: () {
                cameraScreen.switchCameras();
              },
            ),
            CircleButton(
              iconData: Icons.photo_camera,
              onPressed: () async {
                String picture = await cameraScreen.takePicture();
                setState(() {
                  isTyping = true;
                });
                pc.open();
                storageReference =
                    FirebaseStorage().ref().child('${DateTime.now()}');
                task = storageReference.putFile(File(picture));
              },
            ),
            CircleButton(onPressed: null),
          ],
        ),
      ),
      panel: isTyping
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.multiline,
                    autofocus: true,
                    decoration: kTextFieldDecoration,
                    onChanged: (value) {
                      comment = value;
                    },
                  ),
                ),
                FutureBuilder(
                  future: task.onComplete,
                  builder: (context, AsyncSnapshot snapshot) {
                    if (!snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: SizedBox(
                          width: 40.0,
                          height: 40.0,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orangeAccent),
                          ),
                        ),
                      );
                    } else {
                      return CircleButton(
                        iconData: Icons.send,
                        onPressed: () async {
                          final url = await storageReference.getDownloadURL();
                          _firestore.collection('images').add({
                            'url': url,
                            'comment': comment,
                            'time': DateTime.now(),
                          });
                          setState(() {
                            isTyping = false;
                            controller.clear();
                          });
                        },
                      );
                    }
                  },
                ),
              ],
            )
          : ViewScreen(),
    );
  }
}

class ViewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 100.0,
          child: Shimmer.fromColors(
            baseColor: Colors.deepOrange,
            highlightColor: Colors.orangeAccent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_down),
                Text(
                  'Swipe Down For Camera',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: streamBuilder(),
        ),
        SizedBox(
          height: 100.0,
        ),
      ],
    );
  }
}

StreamBuilder<QuerySnapshot> streamBuilder() {
  return StreamBuilder(
    stream: _firestore.collection('images').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Container(
          height: 400,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
            ),
          ),
        );
      }
      final images = snapshot.data.docs;
      images.sort((a, b) => b.get('time').compareTo(a.get('time')));
      List<Widget> imageWidgets = [];
      for (var image in images) {
        final imageURL = image.get('url');
        final imageComment = image.get('comment');
        final Widget imageWidget = Padding(
          padding: EdgeInsets.all(12.5),
          child: ImageCard(imageURL: imageURL, imageComment: imageComment),
        );
        imageWidgets.add(imageWidget);
      }

      return LayoutBuilder(builder: (context, constraints) {
        return CarouselSlider(
          options: CarouselOptions(
            viewportFraction: .775,
            enableInfiniteScroll: false,
            enlargeCenterPage: true,
            height: constraints.maxHeight,
          ),
          items: imageWidgets,
        );
      });
    },
  );
}

class ImageCard extends StatelessWidget {
  ImageCard({
    @required this.imageURL,
    @required this.imageComment,
  });

  final String imageURL;
  final String imageComment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        CachedNetworkImage(
          imageUrl: imageURL,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.5),
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
          placeholder: (context, url) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.5),
              color: Colors.grey,
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
              ),
            ),
          ),
        ),
        LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(12.5),
              ),
              height: constraints.maxHeight / 5,
              width: constraints.maxWidth,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: Text(
                    imageComment,
                    textAlign: TextAlign.center,
                    maxLines: 10,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

//class ImageCard extends StatelessWidget {
//
//  const ImageCard({
//    @required this.imageURL,
//    @required this.imageComment,
//  });
//
//  final String imageURL;
//  final String imageComment;
//
//  @override
//  Widget build(BuildContext context) {
//    return Container(
//      decoration: BoxDecoration(
//        borderRadius: BorderRadius.circular(12.5),
//        image: DecorationImage(
//          fit: BoxFit.cover,
//          image: CachedNetworkImageProvider(imageURL),
//        ),
//      ),
//      child: LayoutBuilder(
//          builder: (BuildContext context, BoxConstraints constraints) {
//        return Align(
//          alignment: Alignment.bottomCenter,
//          child: Container(
//            decoration: BoxDecoration(
//              color: Colors.white70,
//              borderRadius: BorderRadius.circular(12.5),
//            ),
//            height: constraints.maxHeight / 5,
//            width: constraints.maxWidth,
//            child: Center(
//              child: Text(
//                imageComment,
//                textAlign: TextAlign.center,
//                maxLines: 10,
//                style: TextStyle(
//                  color: Colors.grey[700],
//                  fontSize: 12.0,
//                  fontWeight: FontWeight.bold,
//                ),
//              ),
//            ),
//          ),
//        );
//      }),
//    );
//  }
//}
