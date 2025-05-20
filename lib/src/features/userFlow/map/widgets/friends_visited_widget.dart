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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 111,
                  child: Text(
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
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: 111,
                  height: 18,
                  child: Text(
                    '$friendsCount ${_getFriendsText(friendsCount)}',
                    style: TextStyle(
                      color: const Color(0xFF828282),
                      fontSize: 14,
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.w500,
                      height: 1.43,
                      letterSpacing: -0.43,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (avatars.isNotEmpty)
            Container(
              width: 197,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(
                  avatars.length > 5 ? 5 : avatars.length,
                  (index) {
                    return Container(
                      width: 46,
                      height: 46,
                      margin: EdgeInsets.only(left: index == 0 ? 0 : -10),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignOutside,
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(43),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(43),
                        child: Image.network(
                          avatars[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Color(0xFFE0E0E0),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  color: Color(0xFF9E9E9E),
                                  size: 24,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFE0E0E0),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF4A69FF),
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Вспомогательный метод для правильного склонения слова "друзей"
  String _getFriendsText(int count) {
    int rem100 = count % 100;
    int rem10 = count % 10;
    
    if (rem100 >= 11 && rem100 <= 19) {
      return 'друзей';
    } else if (rem10 == 1) {
      return 'друг';
    } else if (rem10 >= 2 && rem10 <= 4) {
      return 'друга';
    } else {
      return 'друзей';
    }
  }
}
