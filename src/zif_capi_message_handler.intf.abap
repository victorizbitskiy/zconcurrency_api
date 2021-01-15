interface ZIF_CAPI_MESSAGE_HANDLER
  public .

  type-pools ABAP .
  type-pools SPTA .

  types:
    BEGIN OF ty_message_list,
      task_id   TYPE guid_32,
      task_name TYPE char30,
      rfcsubrc  TYPE sy-subrc,
      rfcmsg    TYPE spta_t_rfcmsg,
    END OF ty_message_list .
  types:
    ty_message_list_tab TYPE STANDARD TABLE OF ty_message_list WITH KEY task_id .

  methods ADD_MESSAGE
    importing
      !IV_TASK_ID type GUID_32
      !IV_TASK_NAME type CHAR30
      !IV_RFCSUBRC type SY-SUBRC
      !IV_RFCMSG type SPTA_T_RFCMSG .
  methods GET_MESSAGE_LIST
    returning
      value(RT_MESSAGE_LIST) type TY_MESSAGE_LIST_TAB .
endinterface.
