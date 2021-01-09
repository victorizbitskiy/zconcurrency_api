interface ZIF_MESSAGE_HANDLER
  public .


  types:
    BEGIN OF mty_message_list,
           task_id TYPE guid_32,
           task_name TYPE char30,
           rfcsubrc TYPE sy-subrc,
           rfcmsg TYPE spta_t_rfcmsg,
         END OF mty_message_list .
  types:
    mtt_message_list TYPE STANDARD TABLE OF mty_message_list WITH KEY task_id .

  methods ADD_MESSAGE
    importing
      !IV_TASK_ID type GUID_32
      !IV_TASK_NAME type CHAR30
      !IV_RFCSUBRC type SY-SUBRC
      !IV_RFCMSG type SPTA_T_RFCMSG .
  methods GET_MESSAGE_LIST
    returning
      value(RT_MESSAGE_LIST) type MTT_MESSAGE_LIST .
endinterface.
