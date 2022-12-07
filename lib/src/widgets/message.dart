import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/emoji_enlargement_behavior.dart';
import '../models/preview_tap_options.dart';
import '../util.dart';
import 'file_message.dart';
import 'image_message.dart';
import 'inherited_chat_theme.dart';
import 'inherited_user.dart';
import 'text_message.dart';
import 'user_avatar.dart';

/// Base widget for all message types in the chat. Renders bubbles around
/// messages and status. Sets maximum width for a message for
/// a nice look on larger screens.

// [FORK-MODIFICATION] : Message become a StatefulWidget to avoid red screen of death on message delete from Popover.
class Message extends StatefulWidget {
  /// Creates a particular message from any message type
  const Message({
    super.key,
    this.avatarBuilder,
    this.bubbleBuilder,
    this.customMessageBuilder,
    this.customHeaderTag,
    required this.emojiEnlargementBehavior,
    this.fileMessageBuilder,
    required this.hideBackgroundOnEmojiMessages,
    this.imageMessageBuilder,
    required this.isTextMessageTextSelectable,
    required this.message,
    required this.messageWidth,
    this.nameBuilder,
    this.onAvatarTap,
    this.onMessageDoubleTap,
    this.onMessageLongPress,
    this.onMessageStatusLongPress,
    this.onMessageStatusTap,
    this.onMessageTap,
    this.onMessageVisibilityChanged,
    this.onPreviewDataFetched,
    required this.previewTapOptions,
    required this.roundBorder,
    required this.showAvatar,
    required this.showName,
    required this.showStatus,
    required this.showUserAvatars,
    this.textMessageBuilder,
    required this.customPatterns,
    required this.usePreviewData,
  });

  /// This is to allow custom user avatar builder
  /// By using this we can fetch newest user info based on id
  final Widget Function(String userId)? avatarBuilder;

  /// Customize the default bubble using this function. `child` is a content
  /// you should render inside your bubble, `message` is a current message
  /// (contains `author` inside) and `nextMessageInGroup` allows you to see
  /// if the message is a part of a group (messages are grouped when written
  /// in quick succession by the same author)
  final Widget Function(
    Widget child, {
    required types.Message message,
    required bool nextMessageInGroup,
  })? bubbleBuilder;

  /// Build a custom message inside predefined bubble
  final Widget Function(types.CustomMessage, {required int messageWidth})?
      customMessageBuilder;

  /// See [TextMessage.customHeaderTag]
  final Widget Function(BuildContext context)? customHeaderTag;
  /// Controls the enlargement behavior of the emojis in the
  /// [types.TextMessage].
  /// Defaults to [EmojiEnlargementBehavior.multi].
  final EmojiEnlargementBehavior emojiEnlargementBehavior;

  /// Build a file message inside predefined bubble
  final Widget Function(types.FileMessage, {required int messageWidth})?
      fileMessageBuilder;

  /// Hide background for messages containing only emojis.
  final bool hideBackgroundOnEmojiMessages;

  /// Build an image message inside predefined bubble
  final Widget Function(types.ImageMessage, {required int messageWidth})?
      imageMessageBuilder;

  /// See [TextMessage.isTextMessageTextSelectable]
  final bool isTextMessageTextSelectable;

  /// Any message type
  final types.Message message;

  /// Maximum message width
  final int messageWidth;

  /// See [TextMessage.nameBuilder]
  final Widget Function(String userId)? nameBuilder;

  /// See [UserAvatar.onAvatarTap]
  final void Function(types.User)? onAvatarTap;

  /// Called when user double taps on any message
  final void Function(BuildContext context, types.Message)? onMessageDoubleTap;

  /// Called when user makes a long press on any message
  /// [FORK-MODIFICATION] : add borderRadius & mounted for Popover widget
  final void Function(BuildContext context, types.Message, BorderRadiusDirectional borderRadius, bool Function()? mounted)? onMessageLongPress;

  /// Called when user makes a long press on status icon in any message
  final void Function(BuildContext context, types.Message)?
      onMessageStatusLongPress;

  /// Called when user taps on status icon in any message
  final void Function(BuildContext context, types.Message)? onMessageStatusTap;

  /// Called when user taps on any message
  final void Function(BuildContext context, types.Message)? onMessageTap;

  /// Called when the message's visibility changes
  final void Function(types.Message, bool visible)? onMessageVisibilityChanged;

  /// See [TextMessage.onPreviewDataFetched]
  final void Function(types.TextMessage, types.PreviewData)?
      onPreviewDataFetched;

  /// See [TextMessage.previewTapOptions]
  final PreviewTapOptions previewTapOptions;

  /// Rounds border of the message to visually group messages together.
  final bool roundBorder;

  /// Show user avatar for the received message. Useful for a group chat.
  final bool showAvatar;

  /// See [TextMessage.showName]
  final bool showName;

  /// Show message's status
  final bool showStatus;

  /// Show user avatars for received messages. Useful for a group chat.
  final bool showUserAvatars;

  // Enables custom patterns
  final List<MatchText> customPatterns;

  /// Build a text message inside predefined bubble.
  final Widget Function(
    types.TextMessage, {
    required int messageWidth,
    required bool showName,
  })? textMessageBuilder;

  /// See [TextMessage.usePreviewData]
  final bool usePreviewData;

  @override
  _MessageState createState() => _MessageState();
}
class _MessageState extends State<Message> {

  Widget _avatarBuilder() => widget.showAvatar
      ? widget.avatarBuilder?.call(widget.message.author.id) ??
          UserAvatar(author: widget.message.author, onAvatarTap: widget.onAvatarTap)
      : const SizedBox(width: 40);

  Widget _bubbleBuilder(
    BuildContext context,
    BorderRadius borderRadius,
    bool currentUserIsAuthor,
    bool enlargeEmojis,
  ) {
    return widget.bubbleBuilder != null
        ? widget.bubbleBuilder!(
            _messageBuilder(),
            message: widget.message,
            nextMessageInGroup: widget.roundBorder,
          )
        : enlargeEmojis && widget.hideBackgroundOnEmojiMessages
            ? Container(color: Colors.transparent, child: _messageBuilder()) // HOTFIX : remove emoji's glitch when is most recent message
            : Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: !currentUserIsAuthor ||
                          widget.message.type == types.MessageType.image
                      ? InheritedChatTheme.of(context).theme.secondaryColor
                      : InheritedChatTheme.of(context).theme.primaryColor,
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: _messageBuilder(),
                ),
              );
  }

  Widget _messageBuilder() {
    switch (widget.message.type) {
      case types.MessageType.custom:
        final customMessage = widget.message as types.CustomMessage;
        return widget.customMessageBuilder != null
            ? widget.customMessageBuilder!(customMessage, messageWidth: widget.messageWidth)
            : const SizedBox();
      case types.MessageType.file:
        final fileMessage = widget.message as types.FileMessage;
        return widget.fileMessageBuilder != null
            ? widget.fileMessageBuilder!(fileMessage, messageWidth: widget.messageWidth)
            : FileMessage(message: fileMessage);
      case types.MessageType.image:
        final imageMessage = widget.message as types.ImageMessage;
        return widget.imageMessageBuilder != null
            ? widget.imageMessageBuilder!(imageMessage, messageWidth: widget.messageWidth)
            : ImageMessage(message: imageMessage, messageWidth: widget.messageWidth);
      case types.MessageType.text:
        final textMessage = widget.message as types.TextMessage;
        return widget.textMessageBuilder != null
            ? widget.textMessageBuilder!(
                textMessage,
                messageWidth: widget.messageWidth,
                showName: widget.showName,
              )
            : TextMessage(
                emojiEnlargementBehavior: widget.emojiEnlargementBehavior,
                hideBackgroundOnEmojiMessages: widget.hideBackgroundOnEmojiMessages,
                isTextMessageTextSelectable: widget.isTextMessageTextSelectable,
                message: textMessage,
                customHeaderTag: widget.customHeaderTag,
                nameBuilder: widget.nameBuilder,
                onPreviewDataFetched: widget.onPreviewDataFetched,
                previewTapOptions: widget.previewTapOptions,
                showName: widget.showName,
                usePreviewData: widget.usePreviewData,
                customPatterns: widget.customPatterns,
              );
      default:
        return const SizedBox();
    }
  }

  Widget _statusBuilder(BuildContext context) {
    switch (widget.message.status) {
      case types.Status.delivered:
      case types.Status.sent:
        return InheritedChatTheme.of(context).theme.deliveredIcon != null
            ? InheritedChatTheme.of(context).theme.deliveredIcon!
            : Image.asset(
                'assets/icon-delivered.png',
                color: InheritedChatTheme.of(context).theme.primaryColor,
                package: 'flutter_chat_ui',
              );
      case types.Status.error:
        return InheritedChatTheme.of(context).theme.errorIcon != null
            ? InheritedChatTheme.of(context).theme.errorIcon!
            : Image.asset(
                'assets/icon-error.png',
                color: InheritedChatTheme.of(context).theme.errorColor,
                package: 'flutter_chat_ui',
              );
      case types.Status.seen:
        return InheritedChatTheme.of(context).theme.seenIcon != null
            ? InheritedChatTheme.of(context).theme.seenIcon!
            : Image.asset(
                'assets/icon-seen.png',
                color: InheritedChatTheme.of(context).theme.primaryColor,
                package: 'flutter_chat_ui',
              );
      case types.Status.sending:
        return InheritedChatTheme.of(context).theme.sendingIcon != null
            ? InheritedChatTheme.of(context).theme.sendingIcon!
            : Center(
                child: SizedBox(
                  height: 10,
                  width: 10,
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.transparent,
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      InheritedChatTheme.of(context).theme.primaryColor,
                    ),
                  ),
                ),
              );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final user = InheritedUser.of(context).user;
    final currentUserIsAuthor = user.id == widget.message.author.id;
    final enlargeEmojis =
        widget.emojiEnlargementBehavior != EmojiEnlargementBehavior.never &&
            widget.message is types.TextMessage &&
            isConsistsOfEmojis(
                widget.emojiEnlargementBehavior, widget.message as types.TextMessage);
    final messageBorderRadius =
        InheritedChatTheme.of(context).theme.messageBorderRadius;
    final borderRadius = BorderRadiusDirectional.only(
      bottomEnd: Radius.circular(
        currentUserIsAuthor
            ? widget.roundBorder
                ? messageBorderRadius
                : 0
            : messageBorderRadius,
      ),
      bottomStart: Radius.circular(
        currentUserIsAuthor || widget.roundBorder ? messageBorderRadius : 0,
      ),
      topEnd: Radius.circular(messageBorderRadius),
      topStart: Radius.circular(messageBorderRadius),
    );

    return Container(
      alignment: currentUserIsAuthor
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      margin: EdgeInsetsDirectional.only(
        bottom: 4,
        end: kIsWeb ? 0 : query.padding.right,
        start: 20 + (kIsWeb ? 0 : query.padding.left),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!currentUserIsAuthor && widget.showUserAvatars) _avatarBuilder(),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widget.messageWidth.toDouble(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Builder(
                  builder: (BuildContext innerContext) => GestureDetector( // HOTFIX: handle actions on bubble itself.
                    onDoubleTap: () => widget.onMessageDoubleTap?.call(innerContext, widget.message),
                    onLongPress: () => widget.onMessageLongPress?.call(innerContext, widget.message, borderRadius, () => mounted),
                    onTap: () => widget.onMessageTap?.call(innerContext, widget.message),
                    child: widget.onMessageVisibilityChanged != null
                      ? VisibilityDetector(
                          key: Key(widget.message.id),
                          onVisibilityChanged: (visibilityInfo) =>
                              widget.onMessageVisibilityChanged!(widget.message,
                                  visibilityInfo.visibleFraction > 0.1),
                          child: _bubbleBuilder(
                            context,
                            borderRadius.resolve(Directionality.of(context)),
                            currentUserIsAuthor,
                            enlargeEmojis,
                          ),
                        )
                      : _bubbleBuilder(
                          context,
                          borderRadius.resolve(Directionality.of(context)),
                          currentUserIsAuthor,
                          enlargeEmojis,
                        ),
                      )
                ),
              ],
            ),
          ),
          if (currentUserIsAuthor)
            Padding(
              padding: InheritedChatTheme.of(context).theme.statusIconPadding,
              child: widget.showStatus
                  ? GestureDetector(
                      onLongPress: () =>
                          widget.onMessageStatusLongPress?.call(context, widget.message),
                      onTap: () => widget.onMessageStatusTap?.call(context, widget.message),
                      child: _statusBuilder(context),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
