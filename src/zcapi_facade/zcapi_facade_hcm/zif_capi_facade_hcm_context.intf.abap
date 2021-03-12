interface ZIF_CAPI_FACADE_HCM_CONTEXT
  public .


  types:
    BEGIN OF ty_pernrs,
      sign   TYPE c LENGTH 1,
      option TYPE c LENGTH 2,
      low    TYPE n LENGTH 8,
      high   TYPE n LENGTH 8,
    END OF ty_pernrs .
  types:
    ty_t_pernrs TYPE STANDARD TABLE OF ty_pernrs WITH DEFAULT KEY .

  methods SET_PERNRS
    importing
      !IT_PERNRS type TY_T_PERNRS .
  methods GET_PERNRS
    returning
      value(RT_PERNRS) type TY_T_PERNRS .
endinterface.
