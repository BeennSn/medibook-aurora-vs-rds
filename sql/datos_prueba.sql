USE medibook;

INSERT IGNORE INTO pacientes VALUES
(1,'Ana Torres','ana@ejemplo.com'),
(2,'Luis Perez','luis@ejemplo.com');

INSERT IGNORE INTO medicos VALUES
(1,'Carlos Ramirez','Medicina General');

SELECT 'TABLAS CREADAS' AS resultado;
SHOW TABLES;
