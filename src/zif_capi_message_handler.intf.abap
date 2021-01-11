INTERFACE zif_capi_message_handler
  PUBLIC .


  TYPES:
    BEGIN OF mty_message_list,
      task_id   TYPE guid_32,
      task_name TYPE char30,
      rfcsubrc  TYPE sy-subrc,
      rfcmsg    TYPE spta_t_rfcmsg,
    END OF mty_message_list .
  TYPES:
    mtt_message_list TYPE STANDARD TABLE OF mty_message_list WITH KEY task_id .

  METHODS add_message
    IMPORTING
      !iv_task_id   TYPE guid_32
      !iv_task_name TYPE char30
      !iv_rfcsubrc  TYPE sy-subrc
      !iv_rfcmsg    TYPE spta_t_rfcmsg .
  METHODS get_message_list
    RETURNING
      VALUE(rt_message_list) TYPE mtt_message_list .
ENDINTERFACE.
