CLASS zcl_capi_message_handler DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_capi_message_handler .

    METHODS has_messages
      RETURNING
        VALUE(rv_value) TYPE boole_d .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA mt_message_list TYPE zif_capi_message_handler~ty_message_list_tab .
ENDCLASS.



CLASS ZCL_CAPI_MESSAGE_HANDLER IMPLEMENTATION.


  METHOD has_messages.

    IF lines( mt_message_list ) > 0.
      rv_value = abap_true.
    ELSE.
      rv_value = abap_false.
    ENDIF.

  ENDMETHOD.


  METHOD zif_capi_message_handler~add_message.
    DATA: ls_message_list LIKE LINE OF mt_message_list.

    ls_message_list-task_id   = iv_task_id.
    ls_message_list-task_name = iv_task_name.
    ls_message_list-rfcsubrc  = iv_rfcsubrc.
    ls_message_list-rfcmsg    = iv_rfcmsg.

    APPEND ls_message_list TO mt_message_list.

  ENDMETHOD.


  METHOD zif_capi_message_handler~get_message_list.
    rt_message_list = mt_message_list.
  ENDMETHOD.
ENDCLASS.
