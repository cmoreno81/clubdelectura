const double conversationAutoScrollThreshold = 240;

bool shouldAutoScrollAfterPublishing({
  required bool hasScrollPosition,
  required double extentAfter,
}) => !hasScrollPosition || extentAfter < conversationAutoScrollThreshold;
