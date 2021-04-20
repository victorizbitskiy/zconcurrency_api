CLASS zcx_capi_tasks_invocation DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_t100_message .

    CONSTANTS:
      BEGIN OF error_message,
        msgid TYPE symsgid VALUE 'SPTA',
        msgno TYPE symsgno VALUE '004',
        attr1 TYPE scx_attrname VALUE 'SERVER_GROUP',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_message .
    DATA server_group TYPE rfcgr .

    METHODS constructor
      IMPORTING
        !textid       LIKE if_t100_message=>t100key OPTIONAL
        !previous     LIKE previous OPTIONAL
        !server_group TYPE rfcgr OPTIONAL .
protected section.
private section.
ENDCLASS.



CLASS ZCX_CAPI_TASKS_INVOCATION IMPLEMENTATION.


  method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
EXPORTING
PREVIOUS = PREVIOUS
.
me->SERVER_GROUP = SERVER_GROUP .
clear me->textid.
if textid is initial.
  IF_T100_MESSAGE~T100KEY = IF_T100_MESSAGE=>DEFAULT_TEXTID.
else.
  IF_T100_MESSAGE~T100KEY = TEXTID.
endif.
  endmethod.
ENDCLASS.
