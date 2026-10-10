CREATE DATABASE IF NOT EXISTS sistemaacademico;
USE sistemaacademico;

-- 1. Tabla: asignaturas
CREATE TABLE asignaturas (
    id_asignatura INT(11) AUTO_INCREMENT PRIMARY KEY,
    nombre_asignatura VARCHAR(100) NOT NULL,
    codigo_asignatura VARCHAR(20) NOT NULL,
    creditos INT(11) NOT NULL
);

-- 2. Tabla: docentes
CREATE TABLE docentes (
    id_docente VARCHAR(30) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    telefono VARCHAR(20),
    fecha_contrato DATE,
    correo VARCHAR(100)
);

-- 3. Tabla: estudiantes
CREATE TABLE estudiantes (
    id_estudiante VARCHAR(50) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    nombre_tutor VARCHAR(100),
    telefono VARCHAR(20),
    cedula VARCHAR(20),
    fecha_nacimiento DATE,
    estado VARCHAR(15)
);

-- 4. Tabla: grupos
CREATE TABLE grupos (
    id_grupo INT(11) AUTO_INCREMENT PRIMARY KEY,
    anio_grado VARCHAR(10) NOT NULL,
    seccion CHAR(1) NOT NULL,
    anio_electivo YEAR(4) NOT NULL,
    turno VARCHAR(10) NOT NULL
);

-- 5. Tabla: grupo_asignatura
CREATE TABLE grupo_asignatura (
    id_grupo_asign INT(11) AUTO_INCREMENT PRIMARY KEY,
    id_asignatura INT(11) NOT NULL,
    id_grupo INT(11) NOT NULL,
    id_docente VARCHAR(30) NOT NULL,
    fecha_inicio DATE,
    fecha_fin DATE,
    horarios VARCHAR(100),
    CONSTRAINT fk_grupoasign_asignatura FOREIGN KEY (id_asignatura) REFERENCES asignaturas(id_asignatura) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_grupoasign_grupo FOREIGN KEY (id_grupo) REFERENCES grupos(id_grupo) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_grupoasign_docente FOREIGN KEY (id_docente) REFERENCES docentes(id_docente) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 6. Tabla: matricula
CREATE TABLE matricula (
    id_matricula INT(11) AUTO_INCREMENT PRIMARY KEY,
    id_estudiante VARCHAR(50) NOT NULL,
    id_grupo INT(11) NOT NULL,
    fecha_matricula DATE NOT NULL,
    periodo_academico VARCHAR(20) NOT NULL,
    estado_matricula VARCHAR(15) NOT NULL,
    observaciones TEXT,
    CONSTRAINT fk_matricula_estudiante FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id_estudiante) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_matricula_grupo FOREIGN KEY (id_grupo) REFERENCES grupos(id_grupo) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 7. Tabla: asistencia
CREATE TABLE asistencia (
    id_asistencia INT(11) AUTO_INCREMENT PRIMARY KEY,
    id_matricula INT(11) NOT NULL,
    id_grupo_asign INT(11) NOT NULL,
    fecha DATE NOT NULL,
    estado VARCHAR(15) NOT NULL,
    observacion TEXT,
    CONSTRAINT fk_asistencia_matricula FOREIGN KEY (id_matricula) REFERENCES matricula(id_matricula) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_asistencia_grupoasign FOREIGN KEY (id_grupo_asign) REFERENCES grupo_asignatura(id_grupo_asign) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 8. Tabla: calificaciones
CREATE TABLE calificaciones (
    id_calificacion INT(11) AUTO_INCREMENT PRIMARY KEY,
    id_matricula INT(11) NOT NULL,
    id_grupo_asign INT(11) NOT NULL,
    grado DECIMAL(5,2) NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_calificaciones_matricula FOREIGN KEY (id_matricula) REFERENCES matricula(id_matricula) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_calificaciones_grupoasign FOREIGN KEY (id_grupo_asign) REFERENCES grupo_asignatura(id_grupo_asign) ON DELETE CASCADE ON UPDATE CASCADE
);




Select * from estudiantes




CREATE USER 'usuario_proyecto'@'localhost' IDENTIFIED BY 'DJCM170525.';

GRANT ALL PRIVILEGES ON sistemaacademico TO 'usuario_proyecto'@'localhost';

FLUSH PRIVILEGES;

SHOW GRANTS FOR 'usuario_proyecto'@'localhost';



CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(100) NOT NULL,
    correo_electronico VARCHAR(100) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    rol VARCHAR(30) NOT NULL, 
    
   
    id_docente_fk VARCHAR(50) NULL, 
    activo TINYINT(1) DEFAULT 1,
    
    FOREIGN KEY (id_docente_fk) REFERENCES docentes(id_docente) ON DELETE SET NULL
);


CREATE TABLE bitacora (
    id_bitacora INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NULL,                             
    accion VARCHAR(150) NOT NULL,                    
    tabla_afectada VARCHAR(50) NOT NULL,             
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
);



sql
DELIMITER //
CREATE PROCEDURE sp_registrar_calificacion(
    IN p_id_matricula INT,
    IN p_id_grupo_asign INT,
    IN p_grado DECIMAL(5,2)
)
BEGIN
    INSERT INTO calificaciones (id_matricula, id_grupo_asign, grado) 
    VALUES (p_id_matricula, p_id_grupo_asign, p_grado);
END //
DELIMITER ;

sql
DELIMITER //
CREATE PROCEDURE sp_actualizar_calificacion(
    IN p_id_calificacion INT,
    IN p_nuevo_grado DECIMAL(5,2)
)
BEGIN
    UPDATE calificaciones 
    SET grado = p_nuevo_grado 
    WHERE id_calificacion = p_id_calificacion;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_listar_notas_grupo(IN p_id_grupo_asign INT)
BEGIN
    SELECT c.id_calificacion, e.nombre, e.apellido, c.grado, c.fecha_registro
    FROM calificaciones c
    INNER JOIN matricula m ON c.id_matricula = m.id_matricula
    INNER JOIN estudiantes e ON m.id_estudiante = e.id_estudiante
    WHERE c.id_grupo_asign = p_id_grupo_asign;
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER tr_bitacora_update_calificacion
AFTER UPDATE ON calificaciones
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (accion, tabla_afectada)
    VALUES (
        CONCAT('MODIFICACIÓN DE NOTA: En la matrícula ID ', NEW.id_matricula, 
               ' se cambió la nota de (', OLD.grado, ') a (', NEW.grado, ')'),
        'calificaciones'
    );
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tr_bitacora_insert_matricula
AFTER INSERT ON matricula
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (accion, tabla_afectada)
    VALUES (
        CONCAT('NUEVA MATRÍCULA: Se matriculó al estudiante ID (', NEW.id_estudiante, 
               ') en el grupo ID (', NEW.id_grupo, ')'),
        'matricula'
    );
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER tr_bitacora_update_asistencia
AFTER UPDATE ON asistencia
FOR EACH ROW
BEGIN
    -- Solo se registra si el estado realmente cambió
    IF OLD.estado <> NEW.estado THEN
        INSERT INTO bitacora (accion, tabla_afectada)
        VALUES (
            CONCAT('CAMBIO DE ASISTENCIA: Matrícula ID ', NEW.id_matricula, 
                   ' cambió de estado [', OLD.estado, '] a [', NEW.estado, ']'),
            'asistencia'
        );
    END IF;
END //
DELIMITER ;

SELECT * FROM bitacora;


select * from estudiantes

DROP TRIGGER IF EXISTS tr_bitacora_insert_estudiante;
DROP TRIGGER IF EXISTS tr_bitacora_auditoria_estudiante;

DELIMITER //

-- 1. DISPARADOR PARA CUANDO SE REGISTRA
CREATE TRIGGER tr_bitacora_insert_estudiante
AFTER INSERT ON estudiantes
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (accion, tabla_afectada)
    VALUES (
        CONCAT('REGISTRO: Se ingresó al estudiante ', NEW.nombre, ' ', NEW.apellido, ' con ID: ', NEW.id_estudiante),
        'estudiantes'
    );
END //

-- 2. DISPARADOR UNIFICADO PARA MODIFICACIÓN Y ELIMINACIÓN LÓGICA
CREATE TRIGGER tr_bitacora_auditoria_estudiante
AFTER UPDATE ON estudiantes
FOR EACH ROW
BEGIN
    -- CASO A: Si el estado cambió de Activo a Inactivo, es una Eliminación Lógica
    IF OLD.estado = 'Activo' AND NEW.estado = 'Inactivo' THEN
        INSERT INTO bitacora (accion, tabla_afectada)
        VALUES (
            CONCAT('ELIMINACIÓN LÓGICA: Se dio de baja al estudiante ID: ', NEW.id_estudiante, ' (', NEW.nombre, ' ', NEW.apellido, ')'),
            'estudiantes'
        );
    -- CASO B: Si el estado no cambió, significa que modificaron datos generales (nombre, teléfono, etc.)
    ELSE
        INSERT INTO bitacora (accion, tabla_afectada)
        VALUES (
            CONCAT('MODIFICACIÓN: Se actualizaron los datos del estudiante ID: ', NEW.id_estudiante, ' (', NEW.nombre, ' ', NEW.apellido, ')'),
            'estudiantes'
        );
    END IF;
END //

DELIMITER ;

 INSERT INTO usuarios (nombre_completo, correo_electronico, contrasena, rol, id_docente_fk, activo) 
VALUES 
('Josefa fernandez', 'josefa', 'docente123', 'docente', 'DOC01', 1),
('María López Ruiz', 'maria.lopez@escuela.com', 'docente456', 'docente', 'DOC002', 1),
('Carlos Ramírez Soto', 'carlos.ramirez@escuela.com', 'coord123', 'coordinador', NULL, 1),
('Ana Torres Vega', 'ana.torres@escuela.com', 'secre123', 'secretaria', NULL, 1),
('Pedro Sánchez Lima', 'pedro.sanchez@escuela.com', 'temp123', 'docente', 'DOC003', 0);

select * from bitacora

SELECT id_usuario, nombre_completo, rol FROM usuarios;


select * from estudiantes

INSERT INTO estudiantes (nombre, apellido, nombre_tutor, telefono, cedula, fecha_nacimiento, estado)
VALUES ('Jose', 'Cuadra', 'Maria Cuadra', '8888-8888', '001-123456-0001A', '2005-05-10', 'Activo');


UPDATE estudiantes
SET 
    nombre           = 'José Antonio',
    apellido         = 'Cuadra López',
    nombre_tutor     = 'María Cuadra',
    telefono         = '7777-7777',
    cedula           = '001-123456-0001A',
    fecha_nacimiento = '2005-05-10',
    estado           = 'Activo'
WHERE id_estudiante = 'EST001';
