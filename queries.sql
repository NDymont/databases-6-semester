-- 1.  Получить сведения о покупателях, которые не пришли забрать 
-- свой заказ в назначенное им время и общее их число

SELECT distinct pat.*, po.expectedDateReceived
    from Prescriptions prec 
    join Patients pat on prec.patient = pat.id
    join ProductionOrders po on prec.id = po.id
    join OrderStatuses os on os.id = po.status
    where os.name = 'пропал'

with badPatients as (
SELECT distinct pat.*
    from Prescriptions prec 
    join Patients pat on prec.patient = pat.id
    join ProductionOrders po on prec.id = po.id
    join OrderStatuses os on os.id = po.status
    where os.name = 'пропал'
)
select count(id)
    from badPatients


-- 2 
-- Получить перечень и общее число покупателей, которые ждут прибытия 
-- на склад нужных им медикаментов в целом и по указанной категории медикаментов.

select pat.*
    from OrderStatuses os
    join ProductionOrders po on os.id = po.status
    join Prescriptions prec on prec.id = po.id
    join Patients pat on pat.id = prec.patient
    where os.name = 'ожидание доставки ингридиентов'
    order by lastName

select count(*)
    from (
        select pat.*
            from OrderStatuses os
            join ProductionOrders po on os.id = po.status
            join Prescriptions prec on prec.id = po.id
            join Patients pat on pat.id = prec.patient
            where os.name = 'ожидание доставки ингридиентов'
            order by lastName
    )

-- 3
-- Получить перечень десяти наиболее часто используемых медикаментов в целом и указанной категории медикаментов
with AmountMed as (
    select med.name, mt.name as type, sum(prec.amount) as sumAmount
        from Prescriptions prec 
        join Medicines med on prec.medicine = med.id
        join MedicationTypes mt on med.type = mt.id
        group by med.name, mt.name
        order by sumAmount desc
)

select * from AmountMed
    where ROWNUM <= 10

select * from (select * from AmountMed where type = 'настойка')
    where ROWNUM <= 10

-- 5 Получить перечень и общее число покупателей, заказывавших определенное лекарство или определенные типы лекарств за данный период.

with saleInfo as (
    select pat.id as pid, pat.lastName, pat.firstName, med.name as medicine, mt.name as type
    from Patients pat
    join Prescriptions prec on prec.patient = pat.id
    join Medicines med on med.id = prec.medicine
    join MedicationTypes mt on mt.id = med.type
    join Sales sal on sal.id = prec.id
    where sal.saleDate between '01.01.2023' and '30.04.2023'
    order by pat.lastName
    )

select lastName, firstName
    from saleInfo
    where medicine = 'антигриппин'
    order by lastName

select lastName, firstName
    from saleInfo
    where type = 'порошок'
    order by lastName

-- 4 Получить какой объем указанных веществ использован за указанный период.
select sub.name, pre.amount as amoutPartions, iq.amount as amountSubstance 
    from Sales sal join Prescriptions pre on sal.id = pre.id
    join ProductionOrders po on po.id = pre.id
    -- join Medicines med on med.id = pre.medicine
    -- join Recipes rec on rec.id = pre.medicine 
    join IngredientsQuantity iq on iq.recipe = pre.medicine 
    join Substances sub on sub.id = iq.ingredient
    order by sub.name

select sub.name, sum(pre.amount * iq.amount) as totalAmount, mu.name as measureUnit
    from Sales sal join Prescriptions pre on sal.id = pre.id
    join ProductionOrders po on po.id = pre.id
    -- join Medicines med on med.id = pre.medicine
    -- join Recipes rec on rec.id = pre.medicine 
    join IngredientsQuantity iq on iq.recipe = pre.medicine 
    join Substances sub on sub.id = iq.ingredient
    join MeasureUnits mu on mu.id = sub.measureUnit
    where sal.saleDate > '1.01.2023' and sal.saleDate < '1.07.2023'
        and sub.name in ('Аниса плодов масло', 'мяты пречной листья')  
    group by sub.name, mu.name
    order by sub.name

-- 6 Получить перечень и типы лекарств, достигших своей критической нормы или закончившихся.
select med.name, rm.stockQuantity, rm.criticalQuatity, 'Ready Medicines' as type
    from ReadyMedicines rm 
    join Medicines med on rm.id = med.id
    join MedicationTypes mt on med.type = mt.id
    where stockQuantity < criticalQuatity

union 

select name, stockQuantity, criticalQuatity, 'Substance' as type
    from Substances
    where stockQuantity < criticalQuatity

-- 7 Получить перечень лекарств с минимальным запасом на складе в целом и по указанной категории медикаментов.
select *
    from ( 
        select med.name, rm.stockQuantity
            from Medicines med
            join ReadyMedicines rm on rm.id = med.id
            order by rm.stockQuantity
    )
    where ROWNUM <= 10

select *
    from ( 
        select med.name, rm.stockQuantity
            from Medicines med
            join ReadyMedicines rm on rm.id = med.id
            join MedicationTypes mt on mt.id = med.type
            where mt.name = 'мазь'
            order by rm.stockQuantity
    )
    where ROWNUM <= 10

-- 8 Получить полный перечень и общее число заказов находящихся в производстве.
select po.*, med.name
    from OrderStatuses os
    join ProductionOrders po on po.status = os.id
    join Prescriptions prec on prec.id = po.id
    join Medicines med on med.id = prec.medicine

    where os.name = 'в процессе приготовления'

select count(*) from (
    select po.*, med.name
    from OrderStatuses os
    join ProductionOrders po on po.status = os.id
    join Prescriptions prec on prec.id = po.id
    join Medicines med on med.id = prec.medicine

    where os.name = 'в процессе приготовления'
)

-- 9 Получить полный перечень и общее число препаратов требующихся для заказов, находящихся в производстве.
select distinct sub.name
    from OrderStatuses os
    join ProductionOrders po on po.status = os.id
    join Prescriptions prec on prec.id = po.id
    join IngredientsQuantity iq on iq.recipe = prec.medicine
    join Substances sub on sub.id = iq.ingredient

    where os.name = 'в процессе приготовления'

select count(*)
    from (
        select distinct sub.name
            from OrderStatuses os
            join ProductionOrders po on po.status = os.id
            join Prescriptions prec on prec.id = po.id
            join IngredientsQuantity iq on iq.recipe = prec.medicine
            join Substances sub on sub.id = iq.ingredient

            where os.name = 'в процессе приготовления'
    )

-- 10 Получить все технологии приготовления лекарств указанных типов, 
--конкретных лекарств, 
--лекарств, находящихся в справочнике заказов в производстве.
select med.name, sub.name, iq.amount, mu.name, rec.preparationMethod
    from Recipes rec
    join Medicines med on rec.id = med.id
    join IngredientsQuantity iq on rec.id = iq.recipe
    join Substances sub on iq.ingredient = sub.id
    join MeasureUnits mu on sub.measureUnit = mu.id 
    join MedicationTypes mt on mt.id = med.type
    where mt.name = 'порошок'
    order by med.name

select sub.name, iq.amount, mu.name, rec.preparationMethod
    from Recipes rec
    join Medicines med on rec.id = med.id
    join IngredientsQuantity iq on rec.id = iq.recipe
    join Substances sub on iq.ingredient = sub.id
    join MeasureUnits mu on sub.measureUnit = mu.id 
    where med.name = 'антигриппин'

select distinct med.name, sub.name, iq.amount, mu.name, rec.preparationMethod
    from Recipes rec
    join Medicines med on rec.id = med.id
    join IngredientsQuantity iq on rec.id = iq.recipe
    join Substances sub on iq.ingredient = sub.id
    join MeasureUnits mu on sub.measureUnit = mu.id
    join Prescriptions prec on prec.medicine = med.id
    join ProductionOrders po on po.id = prec.id
    join OrderStatuses os on po.status = os.id
    where os.name = 'в процессе приготовления'
    order by med.name


-- 11 Получить сведения о ценах на указанное лекарство в готовом виде, об объеме и ценах на все компоненты, требующиеся для этого лекарства.
select med.name, rec.preparationMethod, sub.name, iq.amount, sub.price
    from Recipes rec 
    join Medicines med on rec.id = med.id
    join IngredientsQuantity iq on iq.recipe = rec.id
    join Substances sub on sub.id = iq.ingredient

with preparationInfo as (
    select med.name as medicine, rec.preparationMethod, sub.name as ingredient, iq.amount, sub.price
        from Recipes rec 
        join Medicines med on rec.id = med.id
        join IngredientsQuantity iq on iq.recipe = rec.id
        join Substances sub on sub.id = iq.ingredient
)

select ingredient, amount, price
    from preparationInfo
    where medicine = 'календулы настойка'

select medicine, preparationMethod, sum(amount * price)
    from preparationInfo
    group by medicine, preparationMethod

-- 12 Получить сведения о наиболее часто делающих заказы клиентах на медикаменты определенного типа, на конкретные медикаменты.
-- 1)
with precInfo as (
    select pat.id as pid, pat.lastName, pat.firstName, med.name as medicine, mt.name as type
    from Patients pat
    join Prescriptions prec on prec.patient = pat.id
    join Medicines med on med.id = prec.medicine
    join MedicationTypes mt on mt.id = med.type
    order by pat.lastName
    ),

freqType as (
    select lastName, firstName, type, count(medicine) as freq
        from precInfo
        group by (lastName, firstName, type)
        order by lastName
    ),

maxFreq as (
    select type, max(freq) as max_freq
        from freqType
        group by (type)
    ),

mostFrequentlyOrderedCustomers as (
    select lastName, firstName, ft.type
        from freqType ft 
        join maxFreq mf on (ft.type = mf.type and ft.freq = mf.max_freq)
        order by type
)

select lastName, firstName
    from mostFrequentlyOrderedCustomers
    where type = 'порошок'

-- 2)
with precInfo as (
    select pat.id as pid, pat.lastName, pat.firstName, med.name as medicine, mt.name as type
    from Patients pat
    join Prescriptions prec on prec.patient = pat.id
    join Medicines med on med.id = prec.medicine
    join MedicationTypes mt on mt.id = med.type
    order by pat.lastName
    ),

freqMed as (
    select lastName, firstName, medicine, count(type) as freq
        from precInfo
        group by (lastName, firstName, medicine)
        order by lastName
    ),

maxFreqM as (
    select medicine, max(freq) as max_freq
        from freqMed
        group by (medicine)
    ),

mostFrequentlyOrderedCustomersM as (
    select lastName, firstName, fm.medicine
        from freqMed fm 
        join maxFreqM mf on (fm.medicine = mf.medicine and fm.freq = mf.max_freq)
        order by medicine
)

select lastName, firstName
    from mostFrequentlyOrderedCustomers
    where medicine = 'антигриппин'


-- 13 Получить сведения о конкретном лекарстве (его тип, способ приготовления, названия всех компонент, цены, его количество на складе).
select med.name, mt.name as type, rm.price, rm.stockQuantity
    from Medicines med
    join ReadyMedicines rm on med.id = rm.id
    join MedicationTypes mt on mt.id = med.type
    order by med.name

select med.name, mt.name as type, sub.name, iq.amount, mu.name, rec.preparationMethod
    from Medicines med
    join Recipes rec on med.id = rec.id
    join IngredientsQuantity iq on rec.id = iq.recipe
    join Substances sub on iq.ingredient = sub.id
    join MeasureUnits mu on sub.measureUnit = mu.id
    join MedicationTypes mt on mt.id = med.type
    order by med.name

with preparationInfo as (
    select med.name as medicine, rec.preparationMethod, sub.name as ingredient, iq.amount, sub.price
        from Recipes rec 
        join Medicines med on rec.id = med.id
        join IngredientsQuantity iq on iq.recipe = rec.id
        join Substances sub on sub.id = iq.ingredient
)
