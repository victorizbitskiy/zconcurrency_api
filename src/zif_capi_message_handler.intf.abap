INTERFACE zif_capi_message_handler
  PUBLIC .


  TYPES:
    BEGIN OF ty_message_list,
      task_id   TYPE guid_32,
      task_name TYPE string,
      rfcsubrc  TYPE i,
      rfcmsg    TYPE spta_t_rfcmsg,
    END OF ty_message_list .
  TYPES:
    ty_message_list_tab TYPE STANDARD TABLE OF ty_message_list WITH KEY task_id .

  METHODS add_message
    IMPORTING
      !iv_task_id   TYPE guid_32
      !iv_task_name TYPE string
      !iv_rfcsubrc  TYPE i
      !iv_rfcmsg    TYPE spta_t_rfcmsg .
  METHODS get_message_list
    RETURNING
      VALUE(rt_result) TYPE ty_message_list_tab .
  METHODS has_messages
    RETURNING
      VALUE(rv_result) TYPE boole_d .
ENDINTERFACE.
