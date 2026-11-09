-- Esquema utilizado en las pruebas reales del laboratorio MediBook.
CREATE DATABASE IF NOT EXISTS medibook;
USE medibook;

CREATE TABLE IF NOT EXISTS pacientes (
  id INT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  correo VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS medicos (
  id INT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  especialidad VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS citas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  paciente_id INT NOT NULL,
  medico_id INT NOT NULL,
  fecha DATE NOT NULL,
  hora TIME NOT NULL,
  estado VARCHAR(20) DEFAULT 'confirmada',
  FOREIGN KEY (paciente_id) REFERENCES pacientes(id),
  FOREIGN KEY (medico_id) REFERENCES medicos(id),
  UNIQUE KEY turno_unico (medico_id, fecha, hora)
);
