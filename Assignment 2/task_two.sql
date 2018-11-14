--1.Crear una vista llamada "MEDIOS_PAGO_CLIENTES" que contenga las siguientes columnas:
--CLIENTE_ID, NOMBRE_CLIENTE (Si tiene el nombre y el apellido separados en columnas, deberán estar unidas en unasola),MEDIO_PAGO_ID,
--TIPO(TDC,Android,Paypal,Efectivo),DETALLES_MEDIO_PAGO, EMPRESARIAL (FALSO o VERDADERO), NOMBRE_EMPRESA (Si lacolumna Empresarial es falso, este campo aparecerá Nulo)
CREATE OR REPLACE VIEW MEDIOS_PAGO_CLIENTES AS
SELECT P.ID CLIENTE_ID,P.NAME || ' ' || P.LAST_NAME NOMBRE_CLIENTE, PM.ID MEDIO_PAGO_ID ,PM.TYPE TIPO,PM.DETAIL DETALLES_MEDIO_PAGO,
CASE 
    WHEN PM.PAY_MODE = 'BUSINESS'
        THEN'TRUE'
        ELSE 'FALSE'
        END AS EMPRESARIAL,
CASE 
    WHEN (CASE 
    WHEN PM.PAY_MODE = 'BUSINESS'
        THEN'TRUE'
        ELSE 'FALSE'
        END)= 'TRUE'
        THEN B.NAME
        ELSE 'NULL'
        END AS NOMBRE_EMPRESA        
FROM PEOPLE P INNER JOIN USERS_BUSINESS_ACCOUNTS UBA ON P.ID = UBA.PEOPLE_ID 
        INNER JOIN  PAYMENT_METHODS PM ON UBA.id = PM.USERS_BUSINESS_ACCOUNTS_ID  
            INNER JOIN  BUSINESS B on UBA.BUSINESS_ID = B.ID
WHERE P.TYPE = 'USER';

SELECT * FROM MEDIOS_PAGO_CLIENTES;

--2. Cree una vista que permita listar los viajes de cada cliente ordenados cronológicamente. El nombre de la vista será “VIAJES_CLIENTES”, 
--loscampos que tendrá son: FECHA_VIAJE,NOMBRE_CONDUCTOR,PLACA_VEHICULO,NOMBRE_CLIENTE,VALOR_TOTAL,TARIFA_DINAMICA(FALSO O VERDADERO),
--TIPO_SERVICIO (UberX o UberBlack),CIUDAD_VIAJE.
--FALTAN ESTAS DOS COLUMNAS VALOR_TOTAL,TARIFA_DINAMICA(FALSO O VERDADERO)


ALTER TABLE TRIPS ADD DYNAMIC_RATE VARCHAR2(255);

ALTER TABLE TRIPS ADD CONSTRAINT "CHK_DYNAMIC_RATE" CHECK (DYNAMIC_RATE IN('TRUE', 'FALSE')) ENABLE;

CREATE OR REPLACE VIEW VIAJES_CLIENTES AS
SELECT T.DATE_TRIP,D.NAME || ' ' || D.LAST_NAME NOMBRE_CONDUCTOR,V.LICENSE_PLATE, U.NAME || ' ' || U.LAST_NAME NOMBRE_CLIENTE,T.VALUE,T.DYNAMIC_RATE,
V.TYPE_UBER,C.NAME
FROM TRIPS T INNER JOIN DRIVERS_VEHICLES DRV ON T.DRIVER_VEHICLE_ID = DRV.ID 
    INNER JOIN PEOPLE D ON DRV.PEOPLE_ID = D.ID 
        INNER JOIN VEHICLES V ON DRV.VEHICLE_ID = V.ID 
            INNER JOIN PEOPLE U ON T.PEOPLE_ID = U.ID 
                INNER JOIN CITIES C ON T.CITY_ID = C.ID;
                
SELECT * FROM VIAJES_CLIENTES;

-- 3. Cree y evidencie el plan de ejecución de la vista VIAJES_CLIENTES. Cree al menos un índice donde
--mejore el rendimiento del query y muestre el nuevo plan de ejecución.
EXPLAIN PLAN
  SET STATEMENT_ID = 'PLAN_VIAJES_CLIENTES' FOR
SELECT * from VIAJES_CLIENTES;

SELECT PLAN_TABLE_OUTPUT 
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'PLAN_VIAJES_CLIENTES','TYPICAL'));

-- nuevo plan de ejecución con indices 
CREATE INDEX  NAME_USER ON PEOPLE(NAME,LAST_NAME);

EXPLAIN PLAN
  SET STATEMENT_ID = 'PLAN_VIAJES_CLIENTES_INDEX' FOR
SELECT * from VIAJES_CLIENTES;

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'PLAN_VIAJES_CLIENTES','TYPICAL'));
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'PLAN_VIAJES_CLIENTES_INDEX','TYPICAL'));

-- 4. Las directivas han decidido implementar el valor de la tarifa por cada kilómetro recorrido y el valor de la tarifa por minuto transcurrido de 
--acuerdo a cada ciudad. También han decidido almacenar el valor de la tarifa base para cada ciudad. Para esto usted deberá crear tres de columnas 
--de tipo numérico y en la tabla que sea conveniente (Se sugiere que sea en la tabla de Ciudades en caso de tenerladisponible) Ejemplo:
--a. Medellín: el valor por cada kilómetro es: 764.525994 pesos colombianos y el valor por minuto es de: 178.571429 pesos colombianos. 
--El valor de la tarifa base es de 2500
--b. Bogotá: el valor por cada kilómetro es:522.43456 pesos colombianos y el valor por minuto esde: 173.1273 pesos colombianos. 
--El valor de la tarifa base es de 2400
--c.Llenar diversos valores para las demás ciudad.

ALTER TABLE CITIES ADD KILOMETER_VALUE NUMBER;
ALTER TABLE CITIES ADD MINUTE_VALUE  NUMBER;
ALTER TABLE CITIES ADD TARIFF_BASE  NUMBER;

--update CITIES set KILOMETER_VALUE=764.525994 , MINUTE_VALUE=178.571429, TARIFF_BASE= 2500
--where ID=1;

SELECT * FROM CITIES;

Insert into UBERDBA.CITIES (ID,NAME,COUNTRY,CURRENCY_ID,KILOMETER_VALUE,MINUTE_VALUE,TARIFF_BASE) values (2,'Bogotá','Colombia',1,522.43456,173.1273, 2400);

--5.Crear una función llamada VALOR_DISTANCIA que reciba la distancia en kilómetros y el nombre de la ciudad donde se hizo el servicio. 
--Con esta información deberá buscar el valor por cada kilómetro dependiendo de la ciudad donde esté ubicado el viaje. 
--Deberá retornar el resultado de multiplicar la distancia recorrida y el valor de cada kilómetro dependiendo de la ciudad. 
--Si la distancia es menor a 0 kilómetros o la ciudad no es válida deberá levantar una excepción propia. Ejemplo: Viaje_ID: 342 
--que fue hecho en Medellín y la distancia fue 20.68km. En este caso deberá retornar 20.68 * 764.525994 =15810.3976.

CREATE OR REPLACE FUNCTION VALOR_DISTANCIA (DISTANCE IN NUMBER,CITY_NAME IN VARCHAR2)
RETURN NUMBER
AS
VALUE_NEGATIVO EXCEPTION;
DISTANCE_VALUE NUMBER :=0;
KILOMETER_VALUE NUMBER :=0;
BEGIN
IF DISTANCE >= 0 THEN 
  SELECT CITIES.KILOMETER_VALUE 
    INTO KILOMETER_VALUE 
    FROM CITIES 
   WHERE  CITIES.NAME = CITY_NAME;
    DISTANCE_VALUE := KILOMETER_VALUE*DISTANCE;
ELSE
     RAISE VALUE_NEGATIVO;
END IF;
  RETURN DISTANCE_VALUE;
EXCEPTION
  WHEN VALUE_NEGATIVO THEN 
  DBMS_OUTPUT.PUT_LINE('LA DISTANCIA NO PUEDE SER NEGATIVA ' || DISTANCE);
  RETURN NULL;
  WHEN NO_DATA_FOUND THEN 
  DBMS_OUTPUT.PUT_LINE('LA CIUDAD NO EXISTE: ' || CITY_NAME);
  RETURN NULL;
  WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE(SQLERRM);
  DBMS_OUTPUT.PUT_LINE(SQLCODE);
  RETURN NULL;
END VALOR_DISTANCIA;

-- 6. Crear una función llamada VALOR_TIEMPO que reciba la cantidad de minutos del servicio y el
--nombre de la ciudad donde se hizo el servicio. Con esta información deberá buscar el valor por cada
--minuto dependiendo de la ciudad donde esté ubicado el viaje. Deberá retornar el resultado de
--multiplicar la distancia recorrida y el valor de cada minuto dependiendo de la ciudad. Si la cantidad de
--minutos es menor a 0 o la ciudad no es válida deberá levantar una excepción propia. Ejemplo:
--Viaje_ID: 342 que fue hecho en Medellín y el tiempo fue 28 minutos. En este caso deberá retornar 28* 178.571429 = 5000.00001

CREATE OR REPLACE FUNCTION VALOR_TIEMPO (QUANTITY_MINUTES IN NUMBER,CITY_NAME IN VARCHAR2)
RETURN NUMBER
AS 
VALUE_NEGATIVO EXCEPTION;
DISTANCE_VALUE NUMBER :=0;
MINUTE_VALUE NUMBER :=0;
BEGIN
IF QUANTITY_MINUTES >= 0 THEN  
    SELECT CITIES.MINUTE_VALUE 
    INTO MINUTE_VALUE 
    FROM CITIES 
    WHERE  CITIES.NAME = CITY_NAME;
    DISTANCE_VALUE := MINUTE_VALUE*QUANTITY_MINUTES;
ELSE
    RAISE VALUE_NEGATIVO;
END IF;
  RETURN DISTANCE_VALUE;
  EXCEPTION
  WHEN VALUE_NEGATIVO THEN 
  DBMS_OUTPUT.PUT_LINE('LA CANTIDAD DE MINUTOS NO PUEDE SER NEGATIVA: ' || quantity_minutes);
  RETURN NULL;
  WHEN NO_DATA_FOUND THEN 
  DBMS_OUTPUT.PUT_LINE('LA CIUDAD NO EXISTE: '||CITY_NAME);
  RETURN NULL;
  WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE(SQLERRM);
  DBMS_OUTPUT.PUT_LINE(SQLCODE);
  RETURN NULL;
END VALOR_TIEMPO;   

-- 7. Crear un procedimiento almacenado que se llame CALCULAR_TARIFA, deberá recibir el ID del viaje.Para calcular la tarifa se requiere lo siguiente:
--a. Si el estado del viaje es diferente a REALIZADO, deberá insertar 0 en el valor de la tarifa.
--b. Buscar el valor de la tarifa base dependiendo de la ciudad donde se haya hecho el servicio.
--c.Invocar la función VALOR_DISTANCIA
--d. Invocar la función VALOR_TIEMPO
--e. Deberá buscar todos los detalles de cada viaje y sumarlos.
--f.Sumar la tarifa base más el resultado de la función VALOR_DISTANCIA más el resultado de
--la función VALOR_TIEMPO y el resultado de la sumatoria de los detalles del viaje.
--g. Actualizar el registro del viaje con el resultado obtenido.
--h. Si alguna de las funciones levanta una excepción, esta deberá ser controlada y actualizar el valor del viaje con 0

CREATE OR REPLACE PROCEDURE CALCULAR_TARIFA(ID_TRIP IN NUMBER) AS
VALUE_TOTAL NUMBER :=0;
VALOR_BASE NUMBER;
STATUS VARCHAR2(255);
VALUE_DISTANCE NUMBER;
VALUE_TIME NUMBER;
NAME_CITY VARCHAR2(255);
DISTANCE_VALUE NUMBER;
TIME_VALUE NUMBER;
DETAIL_VALUE NUMBER;
BEGIN
 SELECT T.STATE_TRIP
    INTO STATUS 
    FROM TRIPS T
    WHERE T.ID= ID_TRIP;
    
IF STATUS <> 'ACCOMPLISHED' THEN 
    UPDATE TRIPS T
    SET VALUE  = 0
    WHERE T.ID = ID_TRIP;
ELSE
    SELECT C.TARIFF_BASE 
    INTO VALOR_BASE 
    FROM CITIES C INNER JOIN TRIPS T ON C.ID = T.CITY_ID 
    WHERE T.ID= ID_TRIP;

    SELECT C.NAME 
    INTO NAME_CITY 
    FROM CITIES C INNER JOIN TRIPS T ON C.ID = T.CITY_ID 
    WHERE T.ID= ID_TRIP;

    SELECT T.DISTANCE 
    INTO DISTANCE_VALUE 
    FROM TRIPS T 
    WHERE T.ID= ID_TRIP;
    
    SELECT T.DURATION_TRIP 
    INTO TIME_VALUE 
    FROM TRIPS T 
    WHERE T.ID= ID_TRIP;
    
    SELECT DISTINCT SUM(C.VALUE) OVER (PARTITION BY BD.BILL_ID)
    INTO DETAIL_VALUE
    FROM TRIPS T INNER JOIN BILLS B ON T.ID = B.TRYP_ID 
        INNER JOIN BILL_DETAILS BD ON B.id = BD.BILL_ID 
            INNER JOIN CONCEPTS C ON BD.CONCEPT_ID = C.ID
    WHERE T.ID = ID_TRIP;
    
    VALUE_DISTANCE := VALOR_DISTANCIA(DISTANCE_VALUE,NAME_CITY);
    VALUE_TIME := VALOR_TIEMPO(TIME_VALUE,NAME_CITY);
    VALUE_TOTAL := VALOR_BASE+VALUE_DISTANCE+VALUE_TIME+DETAIL_VALUE;
    
    UPDATE TRIPS T
    SET VALUE  = VALUE_TOTAL
    WHERE T.ID = ID_TRIP;
END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN 
  DBMS_OUTPUT.PUT_LINE('EL CODIGO DEL VIAJE NO EXISTE: ' || ID_TRIP);
  UPDATE TRIPS T
  SET VALUE  = 0
  WHERE t.ID = ID_TRIP;
  WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE(SQLERRM);
  DBMS_OUTPUT.PUT_LINE(SQLCODE);
   UPDATE TRIPS T
  SET VALUE  = 0
  WHERE t.ID = ID_TRIP;
END CALCULAR_TARIFA;
