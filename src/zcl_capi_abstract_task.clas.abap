CLASS zcl_capi_abstract_task DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_capi_callable .
    INTERFACES if_serializable_object .
    INTERFACES zif_capi_task .

    METHODS constructor
      IMPORTING
        !iv_name TYPE char30 OPTIONAL .
  PROTECTED SECTION.

    CLASS-DATA mv_task_counter TYPE numc10 .
    DATA mv_id TYPE guid_32 .
    DATA mv_name TYPE char30 .

    METHODS create_task_name
      RETURNING
        VALUE(rv_name) TYPE char30 .
    METHODS create_task_id
      RETURNING
        VALUE(rv_guid) TYPE guid_32 .
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CAPI_ABSTRACT_TASK IMPLEMENTATION.


  METHOD constructor.

    create_task_id( ).

    IF iv_name IS SUPPLIED.
      mv_name = iv_name.
    ELSE.
      create_task_name( ).
    ENDIF.

  ENDMETHOD.


  METHOD create_task_id.

    CALL FUNCTION 'GUID_CREATE'
      IMPORTING
        ev_guid_32 = mv_id.

  ENDMETHOD.


  METHOD create_task_name.

    mv_task_counter = mv_task_counter + 1.
    CONCATENATE 'task_' mv_task_counter INTO mv_name.

  ENDMETHOD.


  METHOD zif_capi_callable~call ##NEEDED.
*   This method needs to be overridden
  ENDMETHOD.


  METHOD zif_capi_task~get_id.
    rv_id = mv_id.
  ENDMETHOD.


  METHOD zif_capi_task~get_name.
    rv_name = mv_name.
  ENDMETHOD.
ENDCLASS.
