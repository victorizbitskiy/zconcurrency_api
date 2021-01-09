class ZCL_ABSTRACT_TASK definition
  public
  abstract
  create public .

public section.

  interfaces ZIF_CALLABLE .
  interfaces IF_SERIALIZABLE_OBJECT .
  interfaces ZIF_TASK .

  methods CONSTRUCTOR
    importing
      !IV_NAME type CHAR30 optional .
protected section.

  class-data MV_TASK_COUNTER type NUMC10 .
  data MV_ID type GUID_32 .
  data MV_NAME type CHAR30 .

  methods CREATE_TASK_NAME
    returning
      value(RV_NAME) type CHAR30 .
  methods CREATE_TASK_ID
    returning
      value(RV_GUID) type GUID_32 .
private section.
ENDCLASS.



CLASS ZCL_ABSTRACT_TASK IMPLEMENTATION.


  method CONSTRUCTOR.

    create_task_id( ).

    IF iv_name IS SUPPLIED.
      mv_name = iv_name.
    ELSE.
      create_task_name( ).
    ENDIF.

  endmethod.


  method CREATE_TASK_ID.

    CALL FUNCTION 'GUID_CREATE'
      IMPORTING
        ev_guid_32 = mv_id.

  endmethod.


  method CREATE_TASK_NAME.

    mv_task_counter = mv_task_counter + 1.
    CONCATENATE 'task_' mv_task_counter INTO mv_name.

  endmethod.


  method ZIF_CALLABLE~CALL ##NEEDED.
*   This method needs to be overridden
  endmethod.


  method ZIF_TASK~GET_ID.

    rv_id = mv_id.

  endmethod.


  method ZIF_TASK~GET_NAME.

    rv_name = mv_name.

  endmethod.
ENDCLASS.
