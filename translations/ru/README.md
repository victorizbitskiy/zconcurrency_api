<img src="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/logo/octo.svg" height="100px"/>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/LICENSE)
![ABAP 7.00+](https://img.shields.io/badge/ABAP-7.00%2B-brightgreen)
[![Code Statistics](https://img.shields.io/badge/CodeStatistics-abaplint-blue)](https://abaplint.app/stats/victorizbitskiy/zconcurrency_api)

Переводы:
- [:uk: In English](https://github.com/victorizbitskiy/zconcurrency_api) 

## `ABAP Concurrency API`
ABAP Concurrency API — библиотека, вдохновлённая Java, для параллельного выполнения задач в ABAP с использованием фреймворка SPTA.  

💡 Примечание: Название отсылает к [Java’s concurrency model](https://docs.oracle.com/javase/8/docs/api/index.html?java/util/concurrent/package-summary.html), но по сути задачи выполняются параллельно, а не одновременно, согласно RFC.

---

<p align="center">Не забудь щёлкнуть ⭐, если тебе нравится проект!<p>

---

# Оглавление
1. [Что это такое?](#Что-это-такое)
2. [Зачем это нужно?](#Зачем-это-нужно)
3. [Установка](#Установка)
4. [Использование](#Использование)
5. [Использование в модуле HCM](#Использование-в-модуле-HCM)
6. [UML диаграммы](#Диаграммы)
7. [Зависимости](#Зависимости)
8. [Ограничения](#Ограничения)
9. [Как внести свой вклад](#Как-внести-свой-вклад)
10. [Остались вопросы?](#Остались-вопросы)
12. [Логотип](#Логотип)

## Что это такое?
`ABAP Concurrency API` - это несколько классов, предназначенных для реализации параллельных вычислений.  

## Зачем это нужно?
Реализация параллельных вычислений в ABAP обычно включает следующие шаги:
1. Создание RFC ФМ-а
2. **Реализация** внутри него **бизнес-логики**
3. Асинхронный вызов RFC ФМ-а в цикле
4. Ожидание выполнения и **получение результатов работы**

Если посмотреть на получившийся список, то можно заметить, что по большому счету нас интересует только шаги **`2`** и **`4`**.
Все остальное - это рутинная работа, которая каждый раз занимает время и, потенциально, может быть источником ошибок.

Чтобы не создавать RFC ФМ каждый раз, когда необходимо выполнить параллельную обработку, можно использовать SPTA Framework, который нам предоставил вендор.  
SPTA Framework это хороший инструмент, но интерфейс взаимодействия с ним оставляет желать лучшего. Из-за этого, разработчику приходится прикладывать не малые усилия для того, чтобы реализовать сам процесс распараллеливания.  

Хотя платформа SAP SPTA Framework устраняет необходимость в пользовательских модулях RFC, её низкоуровневый API по-прежнему заставляет разработчиков вручную управлять сериализацией, жизненным циклом задач и обработкой ошибок, что часто приводит к использованию глобальных переменных и ненадежному коду. 

API параллельного выполнения ABAP абстрагирует всё это. Вы определяете, что нужно выполнить (ваша логика) и что вернуть (ваш результат), а платформа сама управляет параллельным выполнением — чисто и безопасно.  

## Установка
Установка выполняется с помощью [abapGit](http://www.abapgit.org).

## Использование
Рассмотрим простую задачу:  

*Необходимо найти квадраты чисел от **`1`** до **`10`***.

Квадрат каждого из чисел будем искать в отдельной задаче/процессе.  
Пример оторван от реального мира, но его достаточно для того, чтобы понять, как работать с API.

Для начала создадим 3 локальных класса: *Контекст*, *Задача* и *Результат*.  
При необходимости вы можете создать глобальные классы.  

1. **lcl_context**, объект этого класса будет инкапсулировать параметры задачи.
Использование этого класса не обязательно. Можно обойтись и без него, передав параметры задачи непосредственно в ее конструктор.
Однако, использование отдельного класса, на мой взгляд, предпочтительнее.

<details>
<summary>Посмотреть код...</summary>
  
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
  
2. **lcl_task**, описывает объект *Задача*. Содержит бизнес-логику (в нашем случае возведение числа в степень 2).
   Обратите внимание, что класс **lcl_task** наследуется от класса **zcl_capi_abstract_task** и переопределяет метод *zif_capi_callable~call*.
<details>
<summary>Посмотреть код...</summary>
  
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

3. **lcl_result** описывает *Результат* выполнения задачи. 
Этот класс должен реализовывать интерфейс **if_serializable_object**. В остальном вы можете описать его произвольным образом.

<details>
<summary>Посмотреть код...</summary>
  
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

**Внимание:**  
Объекты классов **lcl_task** и **lcl_result** сериализуются/десериализуются в процессе выполнения, поэтому избегайте использования статичных атрибутов.
Статичные атрибуты принадлежат классу, а не объекту. Их содержимое при сериализации/десериализации будет утеряно.

Итак, объекты *Контекст*, *Задача* и *Результат* описаны. 
Теперь посмотрим пример их применения:

<details>
<summary>Посмотреть код...</summary>
  
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
            WRITE / lo_result->get( ).
          ENDWHILE.

        ENDIF.

      CATCH zcx_capi_tasks_invocation INTO DATA(lo_capi_tasks_invocation).
        WRITE lo_capi_tasks_invocation->get_text( ).
    ENDTRY.
```
</details>
  
1. Сначала создаем *Коллекцию задач* **lo_tasks**
2. Далее, создаем *Задачу* **lo_task** и добавляем ее в *Коллекцию задач* **lo_tasks**
3. Создаем *Обработчик сообщений* **lo_message_handler** (опционально)
4. Теперь мы подошли к наиболее важной части API - к понятию "сервиса-исполнителя". Сервис-исполнитель асинхронно выполняет переданные в него задачи.  
   В примере мы вызываем статичный метод **zcl_capi_executors=>new_fixed_thread_pool**, который возвращает нам объект **lo_executor** с фиксированным количеством потоков. Метод имеет 4 параметра:

| Имя параметра               | Опционально | Описание                                                     |
| :-------------------------- |   :-----:   | :----------------------------------------------------------- |
| iv_server_group             |             | группа серверов (tcode: RZ12)                                |
| iv_max_no_of_tasks          |             | максимальное количество параллельно выполняющихся задач        |
| iv_no_resubmission_on_error |             | флаг, "**true**"- не запускать повторно задачу при возникновении ошибке |
| io_capi_message_handler     |     X       | объект, который будет содержать сообщения об ошибках (если они произошли) |
  
  Объект lo_executor имеет только один интерфейсный метод **zif_capi_executor_service~invoke_all()**, который принимает на вход *Коллекцию задач* и возвращает *Коллекцию результатов* **lo_results**  (подход заимствован из **java.util.concurrent.***).

5. У *Коллекции результатов* **lo_results** есть итератор, используя который мы легко получаем *Результаты работы* **lo_result** и вызываем у них метод **get( )**.  

В итоге, нам не пришлось создавать RFC ФМ, описывать процесс распараллеливания и т.д.
Все что мы сделали, это описали что собой представляют *Задача* и *Результат*.

**Результат работы:**

![result](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/result.png)

Рассмотренный пример использования `ABAP Concurrency API` можно найти в отчете **ZCONCURRENCY_API_EXAMPLE**.

## Использование в модуле HCM
   Для упрощения работы с ABAP Concurrency API в модуле HCM предлагается использовать реализацию структурного паттерна <a href="https://ru.wikipedia.org/wiki/%D0%A4%D0%B0%D1%81%D0%B0%D0%B4_(%D1%88%D0%B0%D0%B1%D0%BB%D0%BE%D0%BD_%D0%BF%D1%80%D0%BE%D0%B5%D0%BA%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F)">Фасад</a> - пакет ZCAPI_FACADE_HCM. Дополнение инкапсулирует разбиение табельных номеров на пакеты, создание объектов Задача и получение результата. 
  
Рассмотрим задачу:  

*Необходимо по табельным номерам получить ФИО сотрудников*.

ФИО сотрудников будем искать в отдельной задаче/процессе.
Для начала все также создадим 3 класса: *Контекст*, *Задача* и *Результат*.

1. **lcl_context**, объект этого класса будет инкапсулировать параметры задачи. Обратите внимание, что класс *lcl_context* должен быть наследован от абстрактного класса **zcl_capi_facade_hcm_abstr_cntx**. При реализации необходимо переопределить метод *constructor*.

<details>
<base target="_blank">
<summary>Посмотреть код...</summary>
  
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
    DATA ms_params TYPE ty_params.

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

2. **lcl_task**, описывает объект *Задача*. Содержит бизнес-логику (получение ФИО по табельному номеру сотрудника).
  Класс **lcl_task** должен быть наследован от класса **zcl_capi_facade_hcm_abstr_task**. Необходимо реализовать метод *constructor* и переопределить метод *zif_capi_callable~call*.

<details>
<base target="_blank">
<summary>Посмотреть код...</summary>
  
```abap
CLASS lcl_task DEFINITION INHERITING FROM zcl_capi_facade_hcm_abstr_task FINAL.
  PUBLIC SECTION.

    METHODS:
      constructor IMPORTING io_context TYPE REF TO zcl_capi_facade_hcm_abstr_cntx,
      zif_capi_callable~call REDEFINITION.

  PRIVATE SECTION.
    DATA: ms_params TYPE lcl_context=>ty_params.

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
          
    " Simulation of reading the full name of employees by their personnel numbers.
    " The ms_params attribute is available here.
    " We won't be using it in this example, but you can.

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
  
3. **lcl_result** описывает *Результат* выполнения задачи. 
Этот класс должен реализовывать интерфейс **zif_capi_facade_hcm_result**. В остальном вы можете описать его произвольным образом.

<details>
<base target="_blank">
<summary>Посмотреть код...</summary>
  
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

    METHODS:
      constructor IMPORTING it_employees TYPE ty_t_employees.

  PRIVATE SECTION.
    DATA: mt_employees TYPE ty_t_employees.

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

**Внимание:**  
Объекты классов **lcl_task** и **lcl_result** сериализуются/десериализуются в процессе выполнения, поэтому избегайте использования статичных атрибутов.

Итак, объекты *Контекст*, *Задача* и *Результат* описаны. 
Теперь рассмотрим пример их применения:

<details>
<base target="_blank">
<summary>Посмотреть код...</summary>
  
```abap 
    DATA lt_employees TYPE lcl_result=>ty_t_employees.

    " 2 Pernr number per task. For example only.
    " '200' will be fine.
    DATA(lv_package_size) = 2.
  
    DATA(ls_params) =  VALUE lcl_context=>ty_params( begda = sy-datum
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
  
1. Сначала создаем *Контекст* **lo_context**, который содержит параметры запуска *Задачи* 
2. Далее, создаем *Фасад* **lo_capi_facade_hcm**, конструктор которого имеет 4 параметра:

| Имя параметра               | Описание                                                     |
| :-------------------------- | :----------------------------------------------------------- |
| io_context                  | объект, содержащий параметры запуска задачи                  |
| it_pernrs                   | диапазон табельных номеров                                   |
| iv_task_class_name          | имя класса Задача                                            |
| iv_package_size             | количество табельных номеров на одну задачу                  |

3. У объекта **lo_capi_facade_hcm** вызываем метод *execute( )*, который запускает задачи на параллельное выполнение и возвращает результат.

Максимальное количество одновременно работающих задач/процессов вычисляется как 40% от числа свободных диалоговых процессов (DIA, sm50).  
  
Это все, что нужно сделать.

**Результат работы:**

![result](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/result%20HCM.png)

Рассмотренный пример использования Фасада для `ABAP Concurrency API` можно найти в отчете **ZCAPI_FACADE_HCM_EXAMPLE**.
</details>

## Диаграммы
<details>
  <summary>UML диаграмма классов ABAP Concurrency API</summary>
   <p><a target="_blank" rel="noopener noreferrer" href="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Dia.png"><img src="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Dia.png" alt="UML Class Diagram" style="max-width:100%;"></a></p>
</details>
<details>
  <summary>UML диаграмма классов ABAP Concurrency API для HCM</summary>
   <p><a target="_blank" rel="noopener noreferrer" href="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Dia%20ABAP%20CAPI%20for%20HCM.png"><img src="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Dia%20ABAP%20CAPI%20for%20HCM.png" alt="UML Class Diagram HCM" style="max-width:100%;"></a></p>
</details>
<details>
  <summary>UML диаграмма последовательности </summary>
   <p><a target="_blank" rel="noopener noreferrer" href="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Sequence%20Dia.png"><img src="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Sequence%20Dia.png" alt="UML Sequence Diagram" style="max-width:100%;"></a></p>
</details>

## Зависимости
Требуется установленный стандартный пакет разработки **SPTA**.

## Ограничения
Пакетный ввод не поддерживается.  
Это связано с тем, что API использует стандартный SPTA Framework, в котором перед вызовом CALL FUNCTION STARTING NEW TASK не выполняется проверка того, что максимальное количество сеансов пользовательского интерфейса еще не достигнуто (см. ноты [734205](https://launchpad.support.sap.com/#/notes/734205), [710920](https://launchpad.support.sap.com/#/notes/710920)).

## Как внести свой вклад
[Эта инструкция](https://docs.abapgit.org/guide-contributing.html) поможет вам.

## Остались вопросы?
Если у вас есть вопросы или предложения не стесняйтесь отправлять их [(GitHub issue)](https://github.com/victorizbitskiy/zconcurrency_api/issues/new).

## Логотип
Логотип проекта <a href="https://ru.freepik.com/macrovector">designed by macrovector/Freepik</a>
