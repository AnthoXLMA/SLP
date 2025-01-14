import logo from './logo.svg';
import './App.css';
import React from 'react';
import DancerProfileForm from './DancerProfileForm';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
      <h1>Welcome to the Dancer Dating App</h1>
      <DancerProfileForm />
      </header>
    </div>
  );
}
export default App;
