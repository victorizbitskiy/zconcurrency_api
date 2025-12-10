<img src="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/logo/octo.svg" height="100px"/>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/LICENSE)
![ABAP 7.00+](https://img.shields.io/badge/ABAP-7.00%2B-brightgreen)
[![Code Statistics](https://img.shields.io/badge/CodeStatistics-abaplint-blue)](https://abaplint.app/stats/victorizbitskiy/zconcurrency_api)

Translations:
- [:ru: На русском языке](https://github.com/victorizbitskiy/zconcurrency_api/tree/main/translations/ru) 

## `ABAP Concurrency API`

`ABAP Concurrency API` is's a Java-inspired library for parallel task execution in ABAP using the SPTA Framework.  

💡 Note: The name references [Java’s concurrency model](https://docs.oracle.com/javase/8/docs/api/index.html?java/util/concurrent/package-summary.html), but under the hood, tasks run in parallel (not just concurrently) via RFC.

---

<p align="center">Don't forget to click ⭐ if you like the project!<p>

---

# Table of contents
1. [What is it?](#what-is-it)
2. [What does it exist?](#what-does-it-exist)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Usage. HCM module](#using-in-the-HCM-module)
6. [Diagrams](#diagrams)
7. [Dependencies](#dependencies)
8. [Limitations](#limitations)
9. [How to contribute](#how-to-contribute)
10. [Got questions](#Got-questions)
11. [Logo](#logo)

## What is it?

A set of high-level ABAP utility classes that simplify parallel task execution using SAP’s **SPTA Framework**, without requiring manual RFC module creation.

## What does it exist?

Parallel processing in ABAP traditionally follows a tedious pattern:

1. Create an RFC-enabled function module
2. **Implement your business logic** inside it
3. Call it asynchronously in a loop
4. Wait for completion and **retrieve the results**

In practice, only steps **`2`** and **`4`** matter - the rest is repetitive plumbing that’s error-prone and hard to maintain.

While SAP’s SPTA Framework eliminates the need for custom RFC modules, its low-level API still forces developers to manage serialization, task lifecycle, and error handling manually - often leading to global variables and fragile code.

The ABAP Concurrency API abstracts all that away. You define what to run (your logic) and what to return (your result), and the framework handles how it runs in parallel - cleanly and safely.

## Installation

Install the package via [abapGit](http://www.abapgit.org).

## Usage

To illustrate the core concepts, consider a minimal example:  
**Compute the squares of the integers from 1 to 10 in parallel**.

Each number is processed independently in its own parallel task.  
While this example is intentionally simple, it demonstrates the essential workflow of the API-defining a task, executing it in parallel, and collecting results-without domain-specific complexity.

First, define three classes: **Context**, **Task**, and **Result**.
These can be implemented as either local or global classes, depending on whether you need to reuse them across programs.

1. **lcl_context** – encapsulates the input parameters for a task.
Using a dedicated context class is optional; you could pass parameters directly to the task constructor.
However, we strongly recommend using a separate context class to improve code clarity, maintainability, and type safety-especially when dealing with multiple parameters. 
<details>
<base target="_blank">
<summary>Show code...</summary>
   
```abap
CLASS lcl_context DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    TYPES: 
      BEGIN OF ty_params,
        param TYPE i,
      END OF ty_params.

    METHODS: 
      constructor IMPORTING is_params TYPE ty_params,
      get RETURNING VALUE(rs_params) TYPE ty_params.

  PRIVATE SECTION.
    DATA ms_params TYPE ty_params.
ENDCLASS.

CLASS lcl_context IMPLEMENTATION.
  METHOD constructor.
    ms_params = is_params.
  ENDMETHOD.

  METHOD get.
    rs_params = ms_params.
  ENDMETHOD.
ENDCLASS.
```
</details>

2. **lcl_task** – encapsulates the business logic of a parallel unit of work.
This class must inherit from **zcl_capi_abstract_task** and implement the **zif_capi_callable~call** method, where you define what the task actually does.
In this example, the task computes the square of a number provided via its context.
<details>
<base target="_blank">
<summary>Show code...</summary>
   
```abap
CLASS lcl_task DEFINITION INHERITING FROM zcl_capi_abstract_task FINAL.
  PUBLIC SECTION.

    METHODS: 
      constructor IMPORTING io_context TYPE REF TO lcl_context,
      zif_capi_callable~call REDEFINITION.

  PRIVATE SECTION.
    DATA mo_context TYPE REF TO lcl_context.
    DATA mv_res TYPE i.
ENDCLASS.

CLASS lcl_task IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mo_context = io_context.
  ENDMETHOD.

  METHOD zif_capi_callable~call.
   
    DATA(ls_params) = mo_context->get( ).
    mv_res = ls_params-param ** 2.
    
    ro_result = new lcl_result( iv_param  = ls_params-param
                                iv_result = mv_res ).
  ENDMETHOD.
ENDCLASS.
```
</details>
   
3. **lcl_result** – represents the output of a completed task.
This class _must_ implement the **if_serializable_object** interface, because result objects are transferred between work processes via serialization.
Beyond that requirement, you are free to design the structure of the result as needed for your use case-e.g., by exposing getters, defining internal tables, or formatting output strings.
<details>
<base target="_blank">
<summary>Show code...</summary>
   
```abap
CLASS lcl_result DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    METHODS: 
      constructor IMPORTING iv_param  TYPE i
                            iv_result TYPE i,
      get RETURNING VALUE(rv_result) TYPE string.

  PRIVATE SECTION.
    DATA mv_param TYPE i.
    DATA mv_result TYPE i.
ENDCLASS.

CLASS lcl_result IMPLEMENTATION.
  METHOD constructor.
    mv_param = iv_param.
    mv_result = iv_result.
  ENDMETHOD.

  METHOD get.
    rv_result = |{ mv_param } -> { mv_result }|.
  ENDMETHOD.
ENDCLASS.
```
</details>

⚠️ **Important**: Avoid static attributes
All **Context**, **Task**, and **Result** objects are serialized and transferred between dialog work processes.

_Static attributes are not serialized_ - they belong to the class metadata, not to the instance. Any data stored in them will not be transferred to the target process and may lead to inconsistent or incorrect behavior.

Always use instance attributes to hold task-specific state.

With the three core classes defined, let’s walk through a complete usage example.

<details>
<base target="_blank">
<summary>Show code...</summary>
   
```abap
    CONSTANTS lc_server_group TYPE rfcgr VALUE 'parallel_generators'.
    DATA lo_result TYPE REF TO lcl_result.

    " Create collection of tasks
    DATA(lo_tasks) = NEW zcl_capi_collection( ).

    DO 10 TIMES.
   
      DATA(lo_context) = NEW lcl_context( VALUE lcl_context=>ty_params( param = sy-index ) ).
      DATA(lo_task) = NEW lcl_task( lo_context ).
      lo_tasks->zif_capi_collection~add( lo_task ).
   
    ENDDO.

    DATA(lo_message_handler) = NEW zcl_capi_message_handler( ).
    DATA(lv_max_no_of_tasks) = zcl_capi_thread_pool_executor=>max_no_of_tasks( lc_server_group ).
  
    DATA(lo_executor) = zcl_capi_executors=>new_fixed_thread_pool( iv_server_group         = lc_server_group
                                                                   iv_n_threads            = lv_max_no_of_tasks
                                                                   io_capi_message_handler = lo_message_handler ).
    TRY.
        DATA(lo_results) = lo_executor->zif_capi_executor_service~invoke_all( lo_tasks ).

        IF lo_message_handler->zif_capi_message_handler~has_messages( ) = abap_false.

          DATA(lo_results_iterator) = lo_results->get_iterator( ).

          WHILE lo_results_iterator->has_next( ).
            lo_result ?= lo_results_iterator->next( ).
            WRITE: / lo_result->get( ).
          ENDWHILE.

        ENDIF.

      CATCH zcx_capi_tasks_invocation INTO DATA(lo_capi_tasks_invocation).
        WRITE lo_capi_tasks_invocation->get_text( ).
    ENDTRY.
```
</details>
   
1. Create a task collection **lo_tasks**.
2. Instantiate a task **lo_task** and add it to the collection.
3. (Optional) Create a message handler **lo_message_handler** to collect errors from parallel executions.
4. Set up the executor - the core component that runs tasks in parallel.  

In the example, we use the static method **zcl_capi_executors=>new_fixed_thread_pool**, which returns an executor configured to use a fixed number of parallel tasks. This method takes four parameters:

| Parameter name              | Optional | Description                                                   |
| :-------------------------- | :------: | :-------------------------------------------------------------|
| iv_server_group             |          | server group (tcode: RZ12)                                    |
| iv_max_no_of_tasks          |          | maximum number of parallel tasks                            |
| iv_no_resubmission_on_error |          | flag "**true**" - don't restart the task in case of an error  |
| io_capi_message_handler     |   Yes    | an object that will contain error messages (if they occurred) |

  The **lo_executor** object exposes a single interface method: **zif_capi_executor_service~invoke_all()**. This method accepts a collection of tasks and returns a collection of results **lo_results**, following the design pattern used in Java’s **java.util.concurrent package***.

5. The **lo_results** collection provides an iterator, which you can use to retrieve each **lo_result** and call its *get()* method.
As a result, there’s no need to create an RFC function module or manually manage the parallelization logic.
All you had to do was define what your Task does and what your Result looks like.

**Result of execution:**

![result](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/result.png)

A complete working example is available in the report **ZCONCURRENCY_API_EXAMPLE**.

## Using the API in the HCM Module
To simplify parallel processing in the HCM module, the **`ZCAPI_FACADE_HCM`** package provides a Facade implementation (based on the <a href="https://en.wikipedia.org/wiki/Facade_pattern#  :~:text=The%20facade%20pattern%20(also%20spelled,complex%20underlying%20or%20structural%20code.">Facade</a> design pattern).
This facade abstracts away common boilerplate tasks-such as splitting personnel numbers (pernr) into batches, creating task instances, and collecting results-so you can focus on your core business logic.

Let’s consider a simple use case:
**Retrieve the full names of employees by their personnel numbers.**

As with the general API, you’ll need to define three classes: **Context**, **Task**, and **Result**-but now tailored to the HCM facade’s expectations.

1. **lcl_context** – an instance of this class encapsulates the task parameters.
It must inherit from the abstract class **zcl_capi_facade_hcm_abstr_cntx** and override its constructor method to accept and initialize the required parameters.
<details>
<base target="_blank">
<summary>Show code...</summary>
  
  ```abap
  CLASS lcl_context DEFINITION INHERITING FROM zcl_capi_facade_hcm_abstr_cntx FINAL.
  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_params,
        begda TYPE d,
        endda TYPE d,
      END OF ty_params.

    METHODS:
      constructor IMPORTING is_params TYPE ty_params,
      get_params RETURNING VALUE(rs_params) TYPE ty_params.

  PRIVATE SECTION.
    DATA: ms_params TYPE ty_params.

ENDCLASS.

CLASS lcl_context IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    ms_params = is_params.
  ENDMETHOD.

  METHOD get_params.
    rs_params = ms_params.
  ENDMETHOD.
ENDCLASS.
  ```
</details>

2. **lcl_task** – represents the Task object and encapsulates the business logic (e.g., retrieving an employee’s full name by personnel number).
This class must inherit from **zcl_capi_facade_hcm_abstr_task**, implement a constructor to accept the context, and override the **zif_capi_callable~call** method to define the actual task execution.
<details>
<base target="_blank">
<summary>Show code...</summary>
  
```abap
CLASS lcl_task DEFINITION INHERITING FROM zcl_capi_facade_hcm_abstr_task FINAL.
  PUBLIC SECTION.

    METHODS:
      constructor IMPORTING io_context TYPE REF TO zcl_capi_facade_hcm_abstr_cntx,
      zif_capi_callable~call REDEFINITION.

  PRIVATE SECTION.
    DATA ms_params TYPE lcl_context=>ty_params.

ENDCLASS.

CLASS lcl_task IMPLEMENTATION.
  METHOD constructor.
    DATA lo_context TYPE REF TO lcl_context.

    " Set Pernrs numbers to mt_pernrs of Task
    super->constructor( io_context ).

    " Set Context parameters
    lo_context ?= io_context.
    ms_params = lo_context->get_params( ).

  ENDMETHOD.

  METHOD zif_capi_callable~call.
   
    DATA lt_employees TYPE lcl_result=>ty_t_employees.
    DATA ls_employees LIKE LINE OF lt_employees.
          
    " Simulates retrieving employee full names by personnel number.
    " The `ms_params` attribute (e.g., validity dates) is available here.
    " It’s not used in this example, but you can leverage it in your implementation.

    LOOP AT mt_pernrs ASSIGNING FIELD-SYMBOL(<ls_pernr>).
      ls_employees-pernr = <ls_pernr>-low.

      CASE <ls_pernr>-low.
        WHEN 00000001.
          ls_employees-ename = 'John Doe 1'.
        WHEN 00000002.
          ls_employees-ename = 'John Doe 2'.
        WHEN 00000003.
          ls_employees-ename = 'John Doe 3'.
        WHEN 00000004.
          ls_employees-ename = 'John Doe 4'.
        WHEN 00000005.
          ls_employees-ename = 'John Doe 5'.
        WHEN 00000006.
          ls_employees-ename = 'John Doe 6'.
        WHEN 00000007.
          ls_employees-ename = 'John Doe 7'.
        WHEN 00000008.
          ls_employees-ename = 'John Doe 8'.
        WHEN 00000009.
          ls_employees-ename = 'John Doe 9'.
        WHEN 00000010.
          ls_employees-ename = 'John Doe 10'.
        WHEN OTHERS.
      ENDCASE.

      INSERT ls_employees INTO TABLE lt_employees.
    ENDLOOP.

    ro_result = NEW lcl_result( lt_employees ).

  ENDMETHOD.
ENDCLASS.
```

</details>

3. **lcl_result** – represents the result of a task’s execution.
It must implement the **zif_capi_facade_hcm_result** interface. Beyond that requirement, you’re free to define its structure as needed for your use case.
<details>
<base target="_blank">
<summary>Show code...</summary>
  
```abap
CLASS lcl_result DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_capi_facade_hcm_result.

    TYPES:
      BEGIN OF ty_employees,
        pernr TYPE n LENGTH 8,
        ename TYPE string,
      END OF ty_employees,

      ty_t_employees TYPE STANDARD TABLE OF ty_employees WITH KEY pernr.

    METHODS constructor IMPORTING it_employees TYPE ty_t_employees.

  PRIVATE SECTION.
    DATA mt_employees TYPE ty_t_employees.

ENDCLASS.

CLASS lcl_result IMPLEMENTATION.
  METHOD constructor.
    mt_employees = it_employees.
  ENDMETHOD.

  METHOD zif_capi_facade_hcm_result~get.
    et_result = mt_employees.
  ENDMETHOD.                    "get
ENDCLASS.
```
</details>

⚠️ **Important**:
Instances of **lcl_task** and **lcl_result** are serialized and deserialized at runtime. Therefore, avoid using static attributes-they are not preserved during serialization and can lead to unexpected behavior.

With the **Context**, **Task**, and **Result** classes now defined, let’s walk through a complete example.
<details>
<base target="_blank">
<summary>Show code...</summary>
  
```abap 
    DATA lt_employees TYPE lcl_result=>ty_t_employees.

    " 2 Pernr number per task. For example only.
    " '200' will be fine.
    DATA(lv_package_size) = 2.
   
    DATA(ls_params) = VALUE lcl_context=>ty_params( begda = sy-datum
                                                    endda = sy-datum ).
    DATA(lo_context) = NEW lcl_context( ls_params ).

    DATA(lo_capi_facade_hcm) = NEW zcl_capi_facade_hcm( io_context         = lo_context
                                                        it_pernrs          = gt_pernrs
                                                        iv_task_class_name = 'LCL_TASK'
                                                        iv_package_size    = lv_package_size ).
    TRY.
        lo_capi_facade_hcm->execute( IMPORTING et_result = lt_employees ).

        WRITE `PERNR    ENAME`.
        LOOP AT lt_employees ASSIGNING FIELD-SYMBOL(<ls_employees>).
          WRITE: / <ls_employees>-pernr, <ls_employees>-ename.
        ENDLOOP.

      CATCH zcx_capi_tasks_invocation INTO DATA(lo_capi_tasks_invocation).
        WRITE lo_capi_tasks_invocation->get_text( ).
    ENDTRY.
```
</details>

1. Create a context object **lo_context** that holds the parameters to be passed to each task (e.g., validity dates).
2. Instantiate the HCM facade **lo_capi_facade_hcm** using its constructor, which accepts four parameters:

| Parameter name              | Description                                                         |
| :-------------------------- | :-------------------------------------------------------------------|
| io_context                  | An instance of your context class, containing task parameters       |
| it_pernrs                   | A list of personnel numbers (pernr) to process                      |
| iv_task_class_name          | The name of your task class (e.g., 'LCL_TASK')                      |
| iv_package_size             | The number of personnel numbers assigned to each parallel task      |

3. Call the **execute()** method on the facade object.
This triggers parallel execution of tasks and returns the aggregated result.

💡 The maximum number of concurrently running tasks is automatically capped at **40%** of available dialog work processes (visible in transaction SM50) to ensure system stability.

https://github.com/victorizbitskiy/zconcurrency_api/blob/a0507da3ef44c6a6a3da64e216a71e13655594ba/src/zcl_capi_thread_pool_executor.clas.abap#L70

That’s it-no manual task orchestration required.

**Result of execution:**

![result](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/result%20HCM.png)

A complete working example is available in the report **ZCAPI_FACADE_HCM_EXAMPLE**.

## Diagrams
<details>
  <summary>UML Class Diagram ABAP Concurrency API</summary>
   <p><a target="_blank" rel="noopener noreferrer" href="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Dia.png"><img src="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Dia.png" alt="UML Class Diagram" style="max-width:100%;"></a></p>
</details>
<details>
  <summary>UML Class Diagram ABAP Concurrency API for HCM module</summary>
   <p><a target="_blank" rel="noopener noreferrer" href="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Dia%20ABAP%20CAPI%20for%20HCM.png"><img src="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Dia%20ABAP%20CAPI%20for%20HCM.png" alt="UML Class Diagram HCM" style="max-width:100%;"></a></p>
</details>
<details>
  <summary>UML Sequence Diagram </summary>
   <p><a target="_blank" rel="noopener noreferrer" href="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Sequence%20Dia.png"><img src="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Sequence%20Dia.png" alt="UML Sequence Diagram" style="max-width:100%;"></a></p>
</details>

## Dependencies
SPTA package required.

## Limitations
Batch input (BDC) is not supported.
This restriction stems from the underlying use of SAP’s SPTA Framework, which does not allow BDC sessions in parallel task execution.
For further details, refer to SAP Notes [734205](https://launchpad.support.sap.com/#/notes/734205) and [710920](https://launchpad.support.sap.com/#/notes/710920).

## How to contribute
For guidance on contributing to this project, please follow the [abapGit contribution guidelines](https://docs.abapgit.org/guide-contributing.html).
  
## Got questions?
If you have any questions or suggestions, feel free to open a new [(GitHub issue)](https://github.com/victorizbitskiy/zconcurrency_api/issues/new).
  
## Logo
Project logo <a href="https://ru.freepik.com/macrovector">designed by macrovector/Freepik</a>
