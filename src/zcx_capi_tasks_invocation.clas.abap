class ZCX_CAPI_TASKS_INVOCATION definition
  public
  inheriting from CX_STATIC_CHECK
  create public .

public section.

  interfaces IF_T100_MESSAGE .

  constants:
    BEGIN OF error_message,
        msgid TYPE symsgid VALUE 'SPTA',
        msgno TYPE symsgno VALUE '004',
        attr1 TYPE scx_attrname VALUE 'SERVER_GROUP',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_message .
  data SERVER_GROUP type RFCGR .

  methods CONSTRUCTOR
    importing
      !TEXTID like IF_T100_MESSAGE=>T100KEY optional
      !PREVIOUS like PREVIOUS optional
      !SERVER_GROUP type RFCGR optional .
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
