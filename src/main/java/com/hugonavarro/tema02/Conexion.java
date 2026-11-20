package com.hugonavarro.tema02;

import java.sql.*;

public class Conexion {
    public static Connection getConnection() throws SQLException {
        String url = "jdbc:" + Configuracion.DB_DRIVER + "://" + Configuracion.DB_HOST + ":" + Configuracion.DB_PORT + "/" + Configuracion.DB_NAME;
        return DriverManager.getConnection(url, Configuracion.DB_USERNAME, Configuracion.DB_PASSWORD);
    }
}
