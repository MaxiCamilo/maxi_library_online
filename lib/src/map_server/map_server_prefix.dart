mixin MapServerPrefix {
  //Client to server
  static const String clientNewTask = 'ClientNewTask';
  static const String clientChannelItem = 'ClientChannelItem';
  static const String clientCloseChannel = 'ClientCloseChannel';

  //Server to Client
  static const String serverNewTask = 'ServerNewTask';
   //static const String serverNewEvent = 'serverNewEvent';
  static const String serverChannelItem = 'ServerChannelItem';
  static const String serverCloseChannel = 'ServerCloseChannel';
  static const String serverFinishTask = 'ServerFinishTask';
  static const String serverIsCorrect = 'ServerIsCorrect';
  static const String serverHttpResponseID = 'serverHttpResponseID';

  static const String taskID = 'TaskID';
  static const String messageContent = 'MessageContent';
}
