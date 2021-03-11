INTERFACE zif_capi_facade_hcm_context
  PUBLIC .


  TYPES:
    BEGIN OF ty_pernrs,
      sign   TYPE c LENGTH 1,
      option TYPE c LENGTH 2,
      low    TYPE n LENGTH 8,
      high   TYPE n LENGTH 8,
    END OF ty_pernrs .
  TYPES:
    ty_t_pernrs TYPE STANDARD TABLE OF ty_pernrs WITH DEFAULT KEY.

  METHODS set_pernrs
    IMPORTING
      !it_pernrs TYPE ty_t_pernrs .
  METHODS get_pernrs
    RETURNING
      VALUE(rt_pernrs) TYPE ty_t_pernrs .
ENDINTERFACE.
