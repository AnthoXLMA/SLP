import React, { useState } from 'react';
import './DancerProfileForm.css'; // Import the CSS file

const DancerProfileForm = () => {
  const [formData, setFormData] = useState({
    name: '',
    age: '',
    danceStyle: '',
    skillLevel: '',
    favoriteSong: '',
    bio: '',
  });

  const [errors, setErrors] = useState({
    name: '',
    age: '',
    danceStyle: '',
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prevData) => ({
      ...prevData,
      [name]: value,
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    const formErrors = validateForm(formData);
    if (Object.keys(formErrors).length === 0) {
      console.log('Form submitted successfully!', formData);
      // Here you can send the form data to your backend
    } else {
      setErrors(formErrors);
    }
  };

  const validateForm = (data) => {
    const errors = {};
    if (!data.name) errors.name = 'Name is required';
    if (!data.age || isNaN(data.age)) errors.age = 'Valid age is required';
    if (!data.danceStyle) errors.danceStyle = 'Dance style is required';
    return errors;
  };

  return (
    <div className="form-container">
      <h2>Create Your Dancer Profile</h2>
      <form onSubmit={handleSubmit} className="dancer-profile-form">
        <div className="form-group">
          <label htmlFor="name">Full Name</label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name}
            onChange={handleChange}
            placeholder="Enter your full name"
          />
          {errors.name && <p className="error">{errors.name}</p>}
        </div>

        <div className="form-group">
          <label htmlFor="age">Age</label>
          <input
            type="number"
            id="age"
            name="age"
            value={formData.age}
            onChange={handleChange}
            placeholder="Enter your age"
          />
          {errors.age && <p className="error">{errors.age}</p>}
        </div>

        <div className="form-group">
          <label htmlFor="danceStyle">Dance Style</label>
          <select
            id="danceStyle"
            name="danceStyle"
            value={formData.danceStyle}
            onChange={handleChange}
          >
            <option value="">Select your dance style</option>
            <option value="Hip Hop">Hip Hop</option>
            <option value="Salsa">Salsa</option>
            <option value="Ballet">Ballet</option>
            <option value="Contemporary">Contemporary</option>
            <option value="Jazz">Jazz</option>
            <option value="Ballroom">Ballroom</option>
          </select>
          {errors.danceStyle && <p className="error">{errors.danceStyle}</p>}
        </div>

        <div className="form-group">
          <label htmlFor="skillLevel">Skill Level</label>
          <select
            id="skillLevel"
            name="skillLevel"
            value={formData.skillLevel}
            onChange={handleChange}
          >
            <option value="">Select your skill level</option>
            <option value="Beginner">Beginner</option>
            <option value="Intermediate">Intermediate</option>
            <option value="Advanced">Advanced</option>
          </select>
        </div>

        <div className="form-group">
          <label htmlFor="favoriteSong">Favorite Dance Song</label>
          <input
            type="text"
            id="favoriteSong"
            name="favoriteSong"
            value={formData.favoriteSong}
            onChange={handleChange}
            placeholder="Enter your favorite dance song"
          />
        </div>

        <div className="form-group">
          <label htmlFor="bio">Short Bio</label>
          <textarea
            id="bio"
            name="bio"
            value={formData.bio}
            onChange={handleChange}
            placeholder="Tell us something about yourself"
          />
        </div>

        <button type="submit">Submit Profile</button>
      </form>
    </div>
  );
};

export default DancerProfileForm;
