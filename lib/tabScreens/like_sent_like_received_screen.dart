import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LikeSentLikeReceivedScreen extends StatefulWidget {
  const LikeSentLikeReceivedScreen({super.key});

  @override
  State<LikeSentLikeReceivedScreen> createState() => _LikeSentLikeReceivedScreenState();
}

class _LikeSentLikeReceivedScreenState extends State<LikeSentLikeReceivedScreen>
{
  bool isLikeSent = true;
  bool isLikeReceived = true;
  bool isLike = true;
  bool isDislike = true;
  List<String> likeSentKeys = [];
  List<String> likeReceivedKeys = [];
  List<String> likeList = [];

  getLikelistKeys() async
  {
    if(isLikeSent)
    {
      var likeSentDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid).collection('likeSent');
    }
    else
    {
      var likeReceivedDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid).collection(
          'likeReceived');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.8),
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              TextButton(
                  onPressed: ()
                  {

                  },
                  child: Text(
                    "Liked",
                    style: TextStyle(
                      color: isLikeSent ? Colors.blueGrey : Colors.green,
                      fontWeight: isLikeSent ? FontWeight.bold : FontWeight.normal,
                      fontSize: 20,
                    ),
                  )
              ),

              const Text(
                '  |  ',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),

              TextButton(
                  onPressed: ()
                  {

                  },
                  child: Text(
                    "Likes",
                    style: TextStyle(
                      color: isLikeSent ? Colors.blueGrey : Colors.green ,
                      fontWeight: isLikeSent ? FontWeight.bold : FontWeight.normal,
                      fontSize: 20,
                    ),
                  )
              )


            ],
          ),
        ),
        body: Center(
          child: Text(
            "Like Sent Like Received",
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
    );
  }
}
