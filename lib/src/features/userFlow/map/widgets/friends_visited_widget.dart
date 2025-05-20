import 'package:flutter/material.dart';

class FriendsVisitedWidget extends StatelessWidget {
  final List<String> avatars;
  final int friendsCount;

  const FriendsVisitedWidget({
    Key? key,
    required this.avatars,
    required this.friendsCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: const Color(0x194A69FF),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Были друзья:',
                  style: TextStyle(
                    color: const Color(0xFF2F2E2D),
                    fontSize: 18,
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.w600,
                    height: 1.22,
                    letterSpacing: -0.43,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$friendsCount друзей',
                  style: TextStyle(
                    color: const Color(0xFF828282),
                    fontSize: 14,
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                    letterSpacing: -0.43,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(
              avatars.length > 5 ? 5 : avatars.length,
              (index) {
                return Container(
                  width: 46,
                  height: 46,
                  margin: EdgeInsets.only(left: index == 0 ? 0 : -10),
                  decoration: ShapeDecoration(
                    image: DecorationImage(
                      image: NetworkImage(avatars[index]),
                      fit: BoxFit.cover,
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignOutside,
                        color: Colors.white,
                      ),
                      borderRadius: BorderRadius.circular(43),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
