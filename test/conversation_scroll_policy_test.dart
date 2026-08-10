import 'package:club_lectura_app/services/conversation_scroll_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hace auto-scroll si la usuaria estaba cerca del final', () {
    expect(
      shouldAutoScrollAfterPublishing(
        hasScrollPosition: true,
        extentAfter: conversationAutoScrollThreshold - 1,
      ),
      isTrue,
    );
  });

  test('conserva la posición si estaba leyendo comentarios antiguos', () {
    expect(
      shouldAutoScrollAfterPublishing(
        hasScrollPosition: true,
        extentAfter: conversationAutoScrollThreshold + 1,
      ),
      isFalse,
    );
  });
}
