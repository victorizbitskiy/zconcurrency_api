interface ZIF_CAPI_MESSAGE_HANDLER
  public .


  types:
    BEGIN OF ty_message_list,
      task_id   TYPE guid_32,
      task_name TYPE string,
      rfcsubrc  TYPE i,
      rfcmsg    TYPE spta_t_rfcmsg,
    END OF ty_message_list .
  types:
    ty_message_list_tab TYPE STANDARD TABLE OF ty_message_list WITH KEY task_id .

  methods ADD_MESSAGE
    importing
      !IV_TASK_ID type GUID_32
      !IV_TASK_NAME type STRING
      !IV_RFCSUBRC type I
      !IV_RFCMSG type SPTA_T_RFCMSG .
  methods GET_MESSAGE_LIST
    returning
      value(RT_MESSAGE_LIST) type TY_MESSAGE_LIST_TAB .
  methods HAS_MESSAGES
    returning
      value(RV_VALUE) type BOOLE_D .
endinterface.
